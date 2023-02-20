Generator for C++ wrappers for Java
-----------

Update guide for Unity:
- Unity extracts JNIBridge to artifacts/Stevedore/jnibridge-android_<hash>, you can replace it's content with your local build to test your changes
- When ready, run Publish job on Yamato and put resulting artifact descriptor to PlatformDependent/AndroidPlayer/External/manifest.stevedore and run automated tests
- Do PR, merge to master, run publishing job again for master branch and update the manifest again and do smoke test
- Request artifact to be promoted to public in #devs-stevedore and change 'testing' to 'public' in the manifest
- Go with Unity PR
