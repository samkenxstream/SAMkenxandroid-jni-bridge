Generator for C++ wrappers for Java
-----------

This branch is compatible with Java 11 and newer. If you are updating Unity version that uses older Java, search for "release" branch corresponding to that Unity version or make one (recommended to base it on the revision of the currently used build).

Update guide for Unity:
- Unity extracts JNIBridge to artifacts/Stevedore/jnibridge-android_<hash>, you can replace it's content with your local build to test your changes
- When ready, run Publish job on Yamato and put resulting artifact descriptor to PlatformDependent/AndroidPlayer/External/manifest.stevedore and run automated tests
- Do PR, merge to master, run publishing job again for master branch and update the manifest again and do smoke test
- Request artifact to be promoted to public in #devs-stevedore and change 'testing' to 'public' in the manifest
- Go with Unity PR
