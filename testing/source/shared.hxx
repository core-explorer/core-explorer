#pragma once
#include <errno.h>

struct SharedBase {
	__attribute__((visibility("default"))) virtual void muck() = 0;

	__attribute__((visibility("default"))) virtual ~SharedBase() = default;
};

struct SharedDerived : public SharedBase {
	virtual void muck() {}
};

struct
    __attribute__((visibility("default"))) SharedBase2 {
	SharedBase2();
	virtual void mack() = 0;

	//__attribute__((visibility("protected")))
	virtual void meck();

	//__attribute__((visibility("protected")))
	virtual ~SharedBase2();
};

struct SharedBase3 {
	virtual void meck();
	virtual void mack() = 0;

	virtual ~SharedBase3();
};

struct SharedDerived2 : public SharedBase2 {
	SharedDerived2();
	virtual void mack();
};

struct ThreadData {
	virtual ~ThreadData() = default;
	int* ptr = &errno;
	ThreadData* self = this;
	int value = 0;
};

extern thread_local ThreadData* thread_data;

void set_thread_data(int v);