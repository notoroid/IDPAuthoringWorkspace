Pod::Spec.new do |s|

  s.name         = "IDPAuthoringWorkspace"
  s.version      = "0.0.20"
  s.summary      = "IDPAuthoringWorkspace is middleware to realize in the iPhone / iPad on the authoring friendly user interface."

  s.description  = <<-DESC
                   IDPAuthoringWorkspace is middleware to realize in the iPhone / iPad on the authoring friendly user interface. I will support the selection of objects, scaling and rotation. - IDPAuthoringWorkspace はオーサリング向けユーザインタフェイスをiPhone/iPad 上で実現するためのミドルウェアです。オブジェクトの選択、拡大縮小、回転をサポートします。 
                   DESC

  s.homepage     = "https://github.com/notoroid/IDPAuthoringWorkspace"
  s.screenshots  = "https://raw.githubusercontent.com/notoroid/IDPAuthoringWorkspace/master/ScreenShot/ss01.png", "https://raw.githubusercontent.com/notoroid/IDPAuthoringWorkspace/master/ScreenShot/ss02.png", "https://raw.githubusercontent.com/notoroid/IDPAuthoringWorkspace/master/ScreenShot/ss03.png"


  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "notoroid" => "noto@irimasu.com" }
  s.social_media_url   = "http://twitter.com/notoroid"

  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/notoroid/IDPAuthoringWorkspace.git", :tag => "v0.0.19" }

  s.source_files  = "Lib/**/*.{h,m}"
  s.public_header_files = "Lib/**/*.h"

  s.requires_arc = true

end
