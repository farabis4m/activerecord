#
# `pod lib lint SQLite.swift.podspec' fails - see
#    https://github.com/CocoaPods/CocoaPods/issues/4607
#

Pod::Spec.new do |s|
  s.name             = "ActiveRecord"
  s.version          = "0.10.1"
  s.summary          = "ActiveRecord pattern in swift"

  s.description      = <<-DESC
    ActiveRecord close from Swift from
    Rails.
                       DESC

  s.homepage         = "https://github.com/mojidabckuu/ActiveRecord.git"
  s.license          = 'MIT'
  s.author           = { "Vlad Gorbenko" => "vlad.g@mail.com" }
  s.source           = { :git => "https://github.com/mojidabckuu/ActiveRecord.git", :tag => s.version.to_s }

  s.module_name      = 'ActiveRecord'
  s.ios.deployment_target = "8.0"
  s.tvos.deployment_target = "9.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"

  s.preserve_paths = 'CocoaPods/**/*'
  s.pod_target_xcconfig = {
    'SWIFT_INCLUDE_PATHS[sdk=macosx*]'           => '$(SRCROOT)/ActiveRecord/CocoaPods/macosx',
    'SWIFT_INCLUDE_PATHS[sdk=iphoneos*]'         => '$(SRCROOT)/ActiveRecord/CocoaPods/iphoneos',
'SWIFT_INCLUDE_PATHS[sdk=iphoneos10.0]'        => '$(SRCROOT)/SQLite.swift/CocoaPods/iphoneos-10.0',
'SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]'    => '$(SRCROOT)/SQLite.swift/CocoaPods/iphonesimulator',
'SWIFT_INCLUDE_PATHS[sdk=iphonesimulator10.0]' => '$(SRCROOT)/SQLite.swift/CocoaPods/iphonesimulator-10.0',
    'SWIFT_INCLUDE_PATHS[sdk=appletvos*]'        => '$(SRCROOT)/ActiveRecord/CocoaPods/appletvos',
    'SWIFT_INCLUDE_PATHS[sdk=appletvsimulator*]' => '$(SRCROOT)/ActiveRecord/CocoaPods/appletvsimulator',
    'SWIFT_INCLUDE_PATHS[sdk=watchos*]'          => '$(SRCROOT)/ActiveRecord/CocoaPods/watchos',
    'SWIFT_INCLUDE_PATHS[sdk=watchsimulator*]'   => '$(SRCROOT)/ActiveRecord/CocoaPods/watchsimulator'
  }

  s.libraries = 'sqlite3'
  s.source_files = 'ActiveRecord/**/*.{c,h,m,swift}'
  s.private_header_files = 'ActiveRecord/Core/fts3_tokenizer.h'
  s.dependency 'InflectorKit'
end
