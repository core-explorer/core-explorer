#include "shared.hxx"
#include <cstdio>
thread_local ThreadData* thread_data;

static thread_local ThreadData* thread_data2;

SharedBase2::SharedBase2() {}
SharedBase2::~SharedBase2() {}

void SharedDerived2::mack() {
	thread_data2->value = 42;
}

__attribute__((visibility("default"))) SharedDerived2::SharedDerived2() {}

SharedBase3::~SharedBase3() {}

void SharedBase3::meck() {
}

__attribute__((visibility("protected"))) void set_thread_data(int v) {
	thread_data = new ThreadData;
	thread_data->value = v;
	thread_data2 = new ThreadData;
	thread_data2->value = v;
	putc('\n', stderr);
}

inline namespace x {

struct SharedDerived3 : public SharedBase3 {
	virtual void mack();
};
void SharedDerived3::mack() {}

}

void SharedBase2::meck() {
	SharedDerived3 d;
	d.mack();
}