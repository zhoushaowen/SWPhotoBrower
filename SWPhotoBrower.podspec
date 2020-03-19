Pod::Spec.new do |s|

  s.name         = "SWPhotoBrower"

  s.version      = "1.1.9.1"

  s.homepage      = 'https://github.com/zhoushaowen/SWPhotoBrower'

  s.ios.deployment_target = '8.0'

  s.summary      = "图片浏览器"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = { "Zhoushaowen" => "348345883@qq.com" }

  s.source       = { :git => "https://github.com/zhoushaowen/SWPhotoBrower.git", :tag => s.version }
  
  s.source_files  = "SWPhotoBrower/SWPhotoBrower/*.{h,m}"

  s.resource = "SWPhotoBrower/SWPhotoBrower/SWPhotoBrower.bundle"
  
  s.requires_arc = true

  s.dependency 'SDWebImage'
  s.dependency 'MBProgressHUD'



end
