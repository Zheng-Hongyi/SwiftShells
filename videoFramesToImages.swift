#!/usr/bin/env swift

import AVFoundation
import AppKit
let arguments = CommandLine.arguments
if arguments.count <= 1 {
    print("至少有两个参数")
    exit(1)
}
guard let videoPath = arguments[1] as? String else {
    print("第一个参数为视频路径，必须为字符串类型")
    exit(1)
}
guard let saveDir = arguments[2] as? String else {
    print("第二个参数为图片存储路径，必须为字符串类型")
    exit(1)
}
// 创建 AVAsset 对象，该对象表示要获取帧的视频
guard let aUrl = URL(fileURLWithPath: videoPath) as? URL else {
    print("视频路径无效" + videoPath)
    exit(1)
}
let asset = AVAsset(url: aUrl)

// 创建 AVAssetImageGenerator 对象，该对象用于生成视频帧
let generator = AVAssetImageGenerator(asset: asset)

// 设置生成视频帧的属性，例如时间范围、帧率等
generator.appliesPreferredTrackTransform = true // 根据视频方向自动旋转帧
generator.requestedTimeToleranceBefore = CMTime.zero
generator.requestedTimeToleranceAfter = CMTime.zero

// 循环遍历视频的每一帧，并将其转换为 UIImage 对象
let videoTrack = asset.tracks(withMediaType: .video).first!
let videoWidth = videoTrack.naturalSize.width
let videoHeight = videoTrack.naturalSize.height
let videoDuration = CMTimeGetSeconds(asset.duration)
let frameRate = videoTrack.nominalFrameRate
let totalFrames = Int(videoDuration * Double(frameRate))

for i in 0..<totalFrames {
    let time = CMTimeMakeWithSeconds(Double(i) / Double(frameRate), preferredTimescale: 600)
    var actualTime = CMTime.zero
    var imageRef: CGImage?
    do {
        imageRef = try generator.copyCGImage(at: time, actualTime: &actualTime)
    } catch let error {
        print("Error: \(error.localizedDescription)")
    }
    if let imageRef = imageRef {
        let image = NSImage(cgImage: imageRef, size: NSSize(width: imageRef.width, height: imageRef.height))
        if let imageData = image.tiffRepresentation {
            // 创建文件 URL
            let fileURL = URL(fileURLWithPath: "\(saveDir)/\(i).png")

            // 将图片数据写入文件
            do {
                try imageData.write(to: fileURL, options: .atomic)
            } catch {
                print("Failed to write image data to file: \(error)")
            }
        }
    }
}
