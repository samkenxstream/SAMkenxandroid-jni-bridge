#pragma once

#include <atomic>
#include "API.h"
namespace jni
{

class ProxyObject : public virtual ProxyInvoker
{
// Dispatch invoke calls
public:
	static unsigned NumberOfActiveProxies()
	{
#ifdef DISABLE_PROXY_COUNTING
		return 0;
#else
		return proxyCount.load(std::memory_order_relaxed);
#endif
	}

	virtual jobject __Invoke(jclass clazz, jmethodID mid, jobjectArray args);
	virtual void DisableProxy() = 0;

// These functions are special and always forwarded
protected:
	virtual ::jint HashCode() const;
	virtual ::jboolean Equals(const ::jobject arg0) const;
	virtual java::lang::String ToString() const;

	bool __TryInvoke(jclass clazz, jmethodID methodID, jobjectArray args, bool* success, jobject* result);
	virtual bool __InvokeInternal(jclass clazz, jmethodID mid, jobjectArray args, jobject* result) = 0;

// Factory stuff
protected:
	static jobject NewInstance(void* nativePtr, const jobject interfacce);
	static jobject NewInstance(void* nativePtr, const jobject interfacce1, const jobject interfacce2);
	static jobject NewInstance(void* nativePtr, const jobject* interfaces, jsize interfaces_len);
	static void DisableInstance(jobject proxy);

#if !defined(DISABLE_PROXY_COUNTING)
	static std::atomic<unsigned> proxyCount;
#endif
};


template <class RefAllocator, class ...TX>
class ProxyGenerator : public ProxyObject, public TX::__Proxy...
{
public:
	void DisableProxy() override
	{
		auto proxyObject = __ProxyObject();
		if (proxyObject)
		{
			DisableInstance(proxyObject);
			m_ProxyObject.Release();
#if !defined(DISABLE_PROXY_COUNTING)
			proxyCount.fetch_sub(1, std::memory_order_relaxed);
#endif
		}
	}

protected:
	ProxyGenerator() : m_ProxyObject(CreateInstance())
	{
#if !defined(DISABLE_PROXY_COUNTING)
		proxyCount.fetch_add(1, std::memory_order_relaxed);
#endif
	}

	virtual ~ProxyGenerator()
	{
		DisableProxy();
	}

	::jobject __ProxyObject() const override { return m_ProxyObject; }

private:
	inline jobject CreateInstance()
	{
		jobject interfaces[] = { TX::__CLASS... };
		return NewInstance(this, interfaces, sizeof...(TX));
	}

	template<typename... Args> inline void DummyInvoke(Args&&...) {}
	bool __InvokeInternal(jclass clazz, jmethodID mid, jobjectArray args, jobject* result) override
	{
		bool success = false;
		DummyInvoke(ProxyObject::__TryInvoke(clazz, mid, args, &success, result), TX::__Proxy::__TryInvoke(clazz, mid, args, &success, result)...);
		return success;
	}

	Ref<RefAllocator, jobject> m_ProxyObject;
};

template <class ...TX> class Proxy     : public ProxyGenerator<GlobalRefAllocator, TX...> {};
template <class ...TX> class WeakProxy : public ProxyGenerator<WeakGlobalRefAllocator, TX...> {};

}