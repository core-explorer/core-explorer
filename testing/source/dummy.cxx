#include "shared.hxx"
//#include <ext/pool_allocator.h>
#include <malloc.h>
#include <array>
#include <atomic>
#include <csignal>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <thread>
#include <typeinfo>
#include <vector>

struct MainData {
	int* ptr = &errno;
	MainData* self = this;
	int value = 0;
};

thread_local MainData* main_data;

void set_main_data(int v) {
	main_data = new MainData;
	main_data->value = v;
}

struct POD {
	int a;
	char b;
	double c;
};

class Base {
public:
	virtual void foo() = 0;
	virtual ~Base() {}
};

class Derived : public Base {
public:
	virtual void foo() {}

protected:
	bool data = false;
};

class DerivedFromShared : public SharedBase {
public:
	virtual void muck() {}
};

class Base2 {
public:
	virtual void bar() = 0;
	virtual ~Base2() {}
};

class Derived2 : public Base2 {
public:
	virtual void bar() {}

protected:
	bool data = false;
};

class Base3a {
public:
	long a;
};

class Base3b {
public:
	long b;
	virtual long getb() { return b; }
	virtual ~Base3b() {}
};

class Base3ab : public Base3a, public Base3b {
public:
	virtual void baz() {}
	virtual ~Base3ab() {}
};

class Multiple : public Base, Base2, public Base3ab {
public:
	virtual void foo() {}
	virtual void bar() {}
};

namespace named {
class NDerived : public Base {
public:
	virtual void foo() {}
};
}

struct Outer {
	class ODerived : public Base {
	public:
		virtual void foo() {}
	};
	static std::unique_ptr<ODerived> out_of_line;
	static inline std::unique_ptr<ODerived> in_line;
};

template <typename Derived, typename Base>
std::unique_ptr<Derived>
static_unique_ptr_cast(std::unique_ptr<Base>&& p) {
	auto d = static_cast<Derived*>(p.release());
	return std::unique_ptr<Derived>(d);
}

template <typename Derived, typename Base>
std::unique_ptr<Derived>
dynamic_unique_ptr_cast(std::unique_ptr<Base>&& p) {
	auto d = dynamic_cast<Derived*>(p.release());
	return std::unique_ptr<Derived>(d);
}

std::unique_ptr<Outer::ODerived> Outer::out_of_line;
__attribute__((visibility("default"))) std::unique_ptr<Base> varVisible;
__attribute__((visibility("hidden"))) std::unique_ptr<Base> varHidden;

__attribute__((visibility("default"))) std::unique_ptr<Base> funcVisible();
std::unique_ptr<Base> funcVisible() {
	return std::make_unique<Derived>();
}

__attribute__((visibility("hidden"))) std::unique_ptr<Base> funcHidden();
std::unique_ptr<Base> funcHidden() {
	return std::make_unique<Derived>();
}

typedef std::unique_ptr<Base> funcType();
__attribute__((visibility("default"))) funcType* funcPtrVisible = &funcVisible;
__attribute__((visibility("hidden"))) funcType* funcPtrHidden = &funcHidden;

struct Indirect {
	Derived* ptr1 = new Derived();
	std::unique_ptr<Derived> ptr2 = std::make_unique<Derived>();
};

Indirect indirect1;
std::unique_ptr<Indirect> indirect2 = std::make_unique<Indirect>();

void func(POD arg) {
	(void)arg;
	std::vector<int> v;
	v.push_back(1);
	v.push_back(2);
	v.push_back(3);
	v.push_back(4);

	static std::unique_ptr<Base> varStatic = std::make_unique<Derived>();
	if (varStatic) {
		{
			static std::unique_ptr<Base> varNested;
			varNested = std::make_unique<Derived>();
		}
	}

	varVisible = funcPtrVisible();
	varHidden = funcPtrHidden();

	auto pod1 = std::make_unique<POD>();
	auto pod2 = std::make_shared<POD>();

	auto si1 = std::make_unique<Derived>();
	auto si2 = std::make_shared<Derived>();

	auto mi1 = std::make_unique<Multiple>();
	auto mi2 = std::make_shared<Multiple>();

	auto sf1 = std::make_unique<DerivedFromShared>();
	auto sd1 = std::make_unique<SharedDerived>();
	auto se1 = std::make_unique<SharedDerived2>();

	auto ni1 = std::make_unique<named::NDerived>();
	auto ni2 = std::make_shared<named::NDerived>();

	auto oi1 = std::make_unique<Outer::ODerived>();
	auto oi2 = std::make_shared<Outer::ODerived>();

	std::vector<void*> raw_ptrs = {
	    pod1.get(),

	    si1.get(),

	    mi1.get(),
	    sf1.get(),
	    sd1.get(),
	    se1.get(),
	    ni1.get(),
	    oi1.get()

	};

#if defined(__cpp_rtti) || defined(_CPPRTTI)
#define GET_RTTI_PTR(x) &typeid(x)
#define GET_RTTI_NAME(x) typeid(x).name()
#define GET_RTTI_NAME_PTR(x) ((const void*)typeid(x).name())
	printf("RTTI enabled\n");
#else
#define GET_RTTI_PTR(x) nullptr
#define GET_RTTI_NAME(x) "???"
#define GET_RTTI_NAME_PTR(x) nullptr
	printf("RTTI disabled\n");
#endif
	std::vector<const std::type_info*> type_infos = {
	    GET_RTTI_PTR(*pod1),

	    GET_RTTI_PTR(*si1),

	    GET_RTTI_PTR(*mi1),
	    GET_RTTI_PTR(*sf1),
	    GET_RTTI_PTR(*sd1),
	    GET_RTTI_PTR(*se1),
	    GET_RTTI_PTR(*ni1),
	    GET_RTTI_PTR(*oi1)

	};

	for (int i = 0; i < 2; i++) {
		auto memleak = new Derived();
		printf("memleak A %p of type %s\n", (void*)memleak, GET_RTTI_NAME(*memleak));
		memleak = nullptr;
	}

	std::string shortString = "shortString";
	std::string longString = "abcdefghijklmopqrstuvwxyz0123456789?";
	std::u16string shortString16 = u"shortString";

	// raise(SIGTRAP);

	for (size_t i = 0; i < raw_ptrs.size(); ++i) {
		auto& raw = raw_ptrs[i];
		auto& ti = type_infos[i];
		auto& vtable = *(void***)raw;
		auto type_info = ti;
		if (vtable != nullptr) {
			type_info = (const std::type_info*)vtable[-1];
		}
		printf("object %p vtable %p rtti %p name %p %s\n", (void*)raw, (void*)vtable, (void*)type_info,
		    (type_info ? (void*)type_info->name() : nullptr), (type_info ? type_info->name() : "???"));

		auto tti_ptr = GET_RTTI_PTR(*ti);
		auto vtableti = tti_ptr ? *(void***)(tti_ptr) : (void**)nullptr;
		auto type_info_ti = vtableti ? (std::type_info*)vtableti[-1] : (void*)nullptr;
		printf("typeid %p vtable %p rtti %p name %p %s\n", (void*)tti_ptr, (void*)vtableti, (void*)type_info_ti, GET_RTTI_NAME_PTR(*tti_ptr), GET_RTTI_NAME(*tti_ptr));
	}

	for (int i = 0; i < 2; i++) {
		auto memleak = new Derived();
		printf("memleak B %p of type %s\n", (void*)memleak, GET_RTTI_NAME(*memleak));
		memleak = nullptr;
	}

	std::u16string longString16 = u"abcdefghijklmopqrstuvwxyz0123456789?";
	std::u32string shortString32 = U"shortString";
	std::u32string longString32 = U"abcdefghijklmopqrstuvwxyz0123456789?";

	std::atomic<int> atomic(1);
	int tid = 1;
#if 0
	std::thread thread([&atomic, tid] { set_main_data(tid);
	set_thread_data(tid); while(atomic!=0){
		std::this_thread::sleep_for(std::chrono::seconds(1));
		} });
	std::this_thread::sleep_for(std::chrono::milliseconds(100));
#endif
	//raise(SIGTRAP);
	printf("clearing %p \n", (void*)longString32.data());
	longString32 = {};
	printf("new capacity %ld\n", longString32.capacity());
	printf("freeing %p \n", (void*)oi1.get());
	oi1.reset();
	printf("freeing %p \n", (void*)ni1.get());
	ni1.reset();
	uint64_t* ptr = nullptr;
	printf("ptr %ld\n", ptr[0]);
	abort();
	atomic = 0;
#if 0
	thread.join();
#endif
}

int main(int, char**) {
	set_main_data(0);
	set_thread_data(0);
	std::array<POD, 60> arr;
	func(arr[0]);

	//malloc_trim(0);

	return 0;
}
