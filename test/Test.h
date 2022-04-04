#pragma once

#include <jni.h>

void AbortIfErrorsImpl(JNIEnv* env, const char* message, int line);
#define AbortIfErrors(Message) AbortIfErrorsImpl(env, Message, __LINE__);