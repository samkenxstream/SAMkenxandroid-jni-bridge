package bitter.jnibridge;

import java.lang.reflect.*;
import java.lang.invoke.*;

public class JNIBridge
{
	static native Object invoke(long ptr, Class clazz, Method method, Object[] args);

	static Object newInterfaceProxy(final long ptr, final Class[] interfaces)
	{
		return Proxy.newProxyInstance(JNIBridge.class.getClassLoader(), interfaces, new InterfaceProxy(ptr));
	}

	static void disableInterfaceProxy(final Object proxy)
	{
		if (proxy != null)
			((InterfaceProxy) Proxy.getInvocationHandler(proxy)).disable();
	}

	private static class InterfaceProxy implements InvocationHandler
	{
		private Object m_InvocationLock = new Object[0];
		private long m_Ptr;

		@SuppressWarnings("unused")
		public InterfaceProxy(final long ptr)
		{
			m_Ptr = ptr;
		}

		private Object invokeDefault(Object proxy, Throwable t, Method m, Object[] args) throws Throwable
		{
			if (args == null)
			{
				args = new Object[0];
			}
			Class<?> k = m.getDeclaringClass();

			MethodHandle method;
			try
			{
				method = MethodHandles.lookup()
					.findSpecial(k, m.getName(), MethodType.methodType(m.getReturnType(), m.getParameterTypes()), proxy.getClass())
					.bindTo(proxy);
			}
			catch (Exception e)
			{
				System.err.println("JNIBridge error calling default method: " + e.getMessage());
				return null;
			}

			return method.invokeWithArguments(args);
		}

		public Object invoke(Object proxy, Method method, Object[] args) throws Throwable
		{
			synchronized (m_InvocationLock)
			{
				if (m_Ptr == 0)
					return null;

				try
				{
					return JNIBridge.invoke(m_Ptr, method.getDeclaringClass(), method, args);
				}
				catch (NoSuchMethodError e)
				{
					// isDefault() is only available since API 24, but this code path is not hit on lower ones as we generate methods for everything
					if (method.isDefault())
						return invokeDefault(proxy, e, method, args);
					else
					{
						System.err.println("JNIBridge error: Java interface default methods are only supported since Android Oreo");
						throw e;
					}
				}
			}
		}

		public void disable()
		{
			synchronized (m_InvocationLock)
			{
				m_Ptr = 0;
			}
		}
	}
}