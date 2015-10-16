Pod::Spec.new do |s|

  s.name         = "IDPAuthoringWorkspace"
  s.version      = "0.0.24"
  s.summary      = "IDPAuthoringWorkspace is authoring for middleware for user interface on the iPhone / iPad. Selection of objects, scaling, it will support the rotation."

  s.description  = <<-DESC
                    IDPAuthoringWorkspace is authoring for middleware for user interface on the iPhone / iPad. Selection of objects, scaling, it will support the rotation. - IDPAuthoringWorkspace はiPhone/iPad 上でオーサリング向けユーザインタフェイス用ミドルウェアです。オブジェクトの選択、拡大縮小、回転をサポートします。 
                   DESC

  s.homepage     = "https://github.com/notoroid/IDPAuthoringWorkspace"
  s.screenshots  = "https://raw.githubusercontent.com/notoroid/IDPAuthoringWorkspace/master/ScreenShot/ss01.png", "https://raw.githubusercontent.com/notoroid/IDPAuthoringWorkspace/master/ScreenShot/ss02.png", "https://raw.githubusercontent.com/notoroid/IDPAuthoringWorkspace/master/ScreenShot/ss03.png"


  s.license      = "MIT"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "notoroid" => "noto@irimasu.com" }
  s.social_media_url   = "http://twitter.com/notoroid"

  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/notoroid/IDPAuthoringWorkspace.git", :tag => "v0.0.24" }

  s.source_files  = "Lib/**/*.{h,m}"
  s.public_header_files = "Lib/**/*.h"

  s.requires_arc = true

end
