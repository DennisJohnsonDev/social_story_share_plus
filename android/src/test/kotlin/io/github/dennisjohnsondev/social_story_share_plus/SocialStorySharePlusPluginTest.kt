package io.github.dennisjohnsondev.social_story_share_plus

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

/*
 * Once you have built the plugin's example app, you can run these tests from the
 * command line by running `./gradlew testDebugUnitTest` in the `example/android/`
 * directory, or from IDEs that support JUnit such as Android Studio.
 */
internal class SocialStorySharePlusPluginTest {

    @Test
    fun onMethodCall_unknownMethod_returnsNotImplemented() {
        val plugin = SocialStorySharePlusPlugin()
        val call = MethodCall("doesNotExist", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).notImplemented()
    }
}
