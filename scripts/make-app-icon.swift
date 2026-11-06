import AppKit
import Foundation

// Package the original orb for the iOS asset catalog; no new artwork is generated.
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath,isDirectory:true)
let input=root.appendingPathComponent("Piyali/Resources/Brand/piyali-orb.png")
let destination=root.appendingPathComponent("Piyali/Resources/BrandAssets.xcassets/AppIcon.appiconset",isDirectory:true)
try FileManager.default.createDirectory(at:destination,withIntermediateDirectories:true)
guard let source=NSImage(contentsOf:input)?.cgImage(forProposedRect:nil,context:nil,hints:nil),let context=CGContext(data:nil,width:1024,height:1024,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.noneSkipLast.rawValue) else { fatalError("Original orb could not be decoded") }
context.interpolationQuality = .high
context.setFillColor(CGColor(srgbRed:247/255,green:241/255,blue:231/255,alpha:1))
context.fill(CGRect(x:0,y:0,width:1024,height:1024))
context.draw(source,in:CGRect(x:0,y:0,width:1024,height:1024))
guard let image=context.makeImage(),let data=NSBitmapImageRep(cgImage:image).representation(using:.png,properties:[:]) else { fatalError("Icon encoding failed") }
try data.write(to:destination.appendingPathComponent("AppIcon.png"))
let contents:[String:Any] = ["images":[["filename":"AppIcon.png","idiom":"universal","platform":"ios","size":"1024x1024"]],"info":["author":"xcode","version":1]]
try JSONSerialization.data(withJSONObject:contents,options:.prettyPrinted).write(to:destination.appendingPathComponent("Contents.json"))
