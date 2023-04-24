Pod::Spec.new do |s|
  s.name                  = 'YandexDiskKit'
  s.version               = '1.0.0'
  s.summary               = '*Unofficial* Yandex Disk SDK in swift'
  s.homepage              = 'https://github.com/aucl/YandexDiskKit'
  s.license               = 'BSD 2-Clause'
  s.author                = 'Clemens Auer aucl@list.ru'

  s.source                = { :git => "https://github.com/leshkoapps/YandexDiskKit.git", :tag => s.version }
  s.swift_version         = '5'

  s.osx.deployment_target = '10.11'
  s.ios.deployment_target = '9.0'

  s.osx.frameworks        = 'AppKit', 'Webkit', 'SystemConfiguration', 'Foundation'
  s.ios.frameworks        = 'UIKit', 'Webkit', 'SystemConfiguration', 'Foundation'

  s.ios.public_header_files = 'YandexDiskKit/**/*.h'
  s.osx.public_header_files = 'YandexDiskKit/**/*.h'

  s.osx.source_files = "YandexDiskKit/**/*.{swift,h}", "YandexDiskKit/**/*.swift"
  s.ios.source_files = "YandexDiskKit/**/*.{swift,h}", "YandexDiskKit/**/*.swift"

  s.requires_arc = true
end
