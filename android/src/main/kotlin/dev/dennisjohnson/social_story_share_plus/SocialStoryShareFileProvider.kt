package dev.dennisjohnson.social_story_share_plus

import androidx.core.content.FileProvider

// A subclass keeps this provider from clashing with the host app's own FileProvider in the merged manifest.
class SocialStoryShareFileProvider : FileProvider()
