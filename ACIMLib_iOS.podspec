

Pod::Spec.new do |s|
  s.name             = 'ACIMLib_iOS'
  s.version          = '3'
  s.summary          = '...'
  s.description  = <<-DESC
                        ACIMLib test
                      DESC

  s.homepage         = 'https://github.com/iqcc/ACIMLibTest'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'iqcc' => 'muz64034@gmail.com' }
  s.source           = { :git => 'https://github.com/iqcc/ACIMLibTest.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'

  s.ios.vendored_frameworks = 'ACIMLib.xcframework'

  s.dependency 'AliyunOSSiOS'


end
