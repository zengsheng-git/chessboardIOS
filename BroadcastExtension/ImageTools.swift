import CoreImage
import ImageIO
import CoreVideo

/// 帧图像工具：缩放、JPEG 编码、均值哈希（实现细节对齐 Android 版 AnalysisService 的 pHash）。
enum ImageTools {
    private static let ciContext = CIContext(options: nil)

    /// CVPixelBuffer → 最长边不超过 maxDimension 的 CGImage（已缩放）
    static func scaledCGImage(from pixelBuffer: CVPixelBuffer, maxDimension: CGFloat) -> CGImage? {
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let longest = max(ciImage.extent.width, ciImage.extent.height)
        guard longest > 0 else { return nil }
        let scale = min(maxDimension / longest, 1.0)
        if scale < 1.0 {
            guard let filter = CIFilter(name: "CILanczosScaleTransform") else { return nil }
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            filter.setValue(scale, forKey: kCIInputScaleKey)
            filter.setValue(1.0, forKey: kCIInputAspectRatioKey)
            guard let scaled = filter.outputImage else { return nil }
            ciImage = scaled
        }
        return ciContext.createCGImage(ciImage, from: ciImage.extent)
    }

    static func jpegData(from image: CGImage, quality: Double) -> Data? {
        let out = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(out, "public.jpeg" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, image, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return out as Data
    }

    /// 32×32 灰度均值哈希（aHash）：缩放到 32×32 灰度，逐像素与均值比较得 1024 位位图。
    /// 与 Android 版 computePHash 同语义，汉明距离阈值 2 内视为同一画面。
    static func averageHash(of image: CGImage, size: Int = 32) -> [UInt64]? {
        guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                                  bytesPerRow: size, space: CGColorSpaceCreateDeviceGray(),
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        ctx.interpolationQuality = .low
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
        guard let buffer = ctx.data else { return nil }
        let pixels = buffer.bindMemory(to: UInt8.self, capacity: size * size)

        let n = size * size
        var sum = 0
        for i in 0..<n { sum += Int(pixels[i]) }
        let avg = sum / n

        var hash = [UInt64](repeating: 0, count: (n + 63) / 64)
        for i in 0..<n where Int(pixels[i]) >= avg {
            hash[i >> 6] |= (1 << (i & 63))
        }
        return hash
    }

    static func hammingDistance(_ a: [UInt64], _ b: [UInt64]) -> Int {
        guard a.count == b.count else { return Int.max }
        var distance = 0
        for i in a.indices {
            distance += (a[i] ^ b[i]).nonzeroBitCount
        }
        return distance
    }
}
