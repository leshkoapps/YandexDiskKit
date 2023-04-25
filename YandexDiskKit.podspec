Pod::Spec.new do |s|
  s.name                  = 'YandexDiskKit'
  s.version               = '1.0.1'
  s.summary               = '*Unofficial* Yandex Disk SDK in swift'
  s.homepage              = 'https://github.com/aucl/YandexDiskKit'
  s.license               = 'BSD 2-Clause'
  s.author                = 'Clemens Auer aucl@list.ru'
  s.source                = { :git => "https://github.com/leshkoapps/YandexDiskKit.git", :tag => s.version }
  s.swift_version         = '5'
  s.ios.deployment_target = '11.0'
  s.ios.frameworks        = 'SystemConfiguration', 'Foundation'
  s.ios.public_header_files = 'YandexDiskKit/**/*.h'
  s.ios.source_files = "YandexDiskKit/**/*.{swift,h}", "YandexDiskKit/**/*.swift"
  s.requires_arc = true
end
