#include <jni.h>
#include "API.h"
#include "Test.h"
#include <string.h>
#include <assert.h>
#include <string>
#include <algorithm>

static jobject s_CustomClassLoader = 0;
static jmethodID s_ClassForNameMethod = 0;
static int s_ClassLoaderCallCount = 0;

jclass FindClass(JNIEnv* env, const char* name)
{
    // Taken from Unity code
    env->ExceptionClear();
    jclass clazz = env->FindClass("java/lang/Class");
    jboolean initialize = JNI_TRUE;

    std::string qualifiedName = name;
    std::replace(qualifiedName.begin(), qualifiedName.end(), '/', '.');
    jstring java_name = env->NewStringUTF(qualifiedName.c_str());
    jclass klass = (jclass)env->CallStaticObjectMethod(clazz, s_ClassForNameMethod, java_name, initialize, s_CustomClassLoader);
    env->DeleteLocalRef(java_name);
    env->DeleteLocalRef(clazz);
    s_ClassLoaderCallCount++;
    return klass;
}

void AllocateClassLoader(JNIEnv* env)
{
    jclass jniBridgeClass = env->FindClass("bitter/jnibridge/JNIBridge");
    jclass classClass = env->GetObjectClass(jniBridgeClass);

    // This piece of code taken from Unity (EntryPoint.cpp void InitJni(JavaVM* jvm, jobject obj, jobject context))
    jclass classLoaderClass = env->FindClass("java/lang/ClassLoader");
    jmethodID getClassLoaderMethod = env->GetMethodID(classClass, "getClassLoader", "()Ljava/lang/ClassLoader;");
    jobject temp = env->CallObjectMethod(jniBridgeClass, getClassLoaderMethod);

    if (env->ExceptionCheck())
        AbortIfErrors("Failed to acquire class loader");

    s_CustomClassLoader = env->NewGlobalRef(temp);
    s_ClassForNameMethod = env->GetStaticMethodID(classClass, "forName", "(Ljava/lang/String;ZLjava/lang/ClassLoader;)Ljava/lang/Class;");


    AbortIfErrors("Couldn't allocate class loader");
}

void DeallocateClassLoader(JNIEnv* env)
{
    env->DeleteGlobalRef(s_CustomClassLoader);
    s_CustomClassLoader = 0;
    s_ClassForNameMethod = 0;
}

void TestOverrides(JavaVM* vm, JNIEnv* env)
{
    AllocateClassLoader(env);

    jni::CallbackOverrides overrides;
    overrides.FindClass = FindClass;
    jni::Initialize(*vm, &overrides);
    
    int oldCallCount;
    jclass klass;

    oldCallCount = s_ClassLoaderCallCount;
    klass = jni::FindClass("bitter/jnibridge/JNIBridge");
    assert(s_ClassLoaderCallCount == 1 + oldCallCount && klass && "Failed to get bitter.jnibridge.JNIBridge class via class loader");

    oldCallCount = s_ClassLoaderCallCount;
    klass = jni::FindClass("java.lang.ClassLoader");
    assert(s_ClassLoaderCallCount == 1 + oldCallCount && klass && "Failed to get java.lang.ClassLoader class via class loader");

    klass = jni::FindClass("java.lang.ClassLoader2");
    assert(klass == NULL && "We shouldn't suppose to find the class");
    assert(env->ExceptionCheck() && "Was expecting exception to be set");
    env->ExceptionClear();

    DeallocateClassLoader(env);
    jni::Shutdown();
}