Pod::Spec.new do |s|
  s.name             = 'social_story_share_plus'
  s.version          = '0.1.0'
  s.summary          = 'Share images to Instagram Stories, Facebook Stories and WhatsApp Status from Flutter.'
  s.description      = <<-DESC
Share images to Instagram Stories, Facebook Stories and WhatsApp Status, send text to Instagram Direct and save images to the gallery.
                       DESC
  s.homepage         = 'https://pub.dev/packages/social_story_share_plus'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Dennis Johnson'
  s.source           = { :path => '.' }
  s.source_files = 'social_story_share_plus/Sources/social_story_share_plus/**/*.swift'
  s.dependency 'Flutter'
  s.frameworks = 'Photos'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.resource_bundles = {'social_story_share_plus_privacy' => ['social_story_share_plus/Sources/social_story_share_plus/PrivacyInfo.xcprivacy']}
end
