package dev.dennisjohnson.social_story_share_plus

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

internal class SocialStorySharePlusPluginTest {
    @Test
    fun onMethodCall_unknownMethod_isNotImplemented() {
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        SocialStorySharePlusPlugin().onMethodCall(MethodCall("unknown", null), result)

        Mockito.verify(result).notImplemented()
    }

    @Test
    fun onMethodCall_shareWithoutActivity_reportsUiUnavailable() {
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        val call = MethodCall("shareToWhatsAppStatus", mapOf("imagePath" to "/tmp/poster.png"))

        SocialStorySharePlusPlugin().onMethodCall(call, result)

        Mockito.verify(result).error(Mockito.eq("UI_UNAVAILABLE"), Mockito.anyString(), Mockito.isNull())
    }
}
