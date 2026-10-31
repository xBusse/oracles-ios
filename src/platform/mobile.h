#pragma once
// Which phone the app runs on. ORACLES_MOBILE covers what Android and iOS share (fullscreen only, the
// touch overlay, no portable mode, no self-update); the JNI and logcat pieces stay __ANDROID__.
#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#if defined(__APPLE__) && TARGET_OS_IOS
#define ORACLES_IOS 1
#endif

#if defined(__ANDROID__) || defined(ORACLES_IOS)
#define ORACLES_MOBILE 1
#endif
