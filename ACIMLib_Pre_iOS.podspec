

Pod::Spec.new do |s|
  s.name             = 'ACIMLib_Pre_iOS'
  s.version          = '11'
  s.summary          = 'IM SDK'
  s.description  = <<-DESC
                       IM SDK for iOS.
                      DESC

  s.homepage         = 'https://github.com/iqcc/ACIMLibTest'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'CoderZmu' => 'muz64034@gmail.com' }
  s.source           = { :git => 'https://github.com/CoderZmu/ACIMLibTest.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.platform     = :ios, "11.0"

  s.vendored_frameworks = 'ACIMLib.xcframework'
  s.dependency 'AliyunOSSiOS'
  s.dependency 'libwebp'


end
