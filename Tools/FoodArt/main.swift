import AppKit
import CoreImage
import Foundation
import ImagePlayground
import UniformTypeIdentifiers
import Vision

// 用 Image Playground 给每种食材生成一张 3D 动画风格的图，再用 Vision 抠掉背景，
// 裁切成正方形透明 PNG，写进资源目录。
//
//   foodart <输出目录> [食材名...]      不传食材名就全部生成；已有的跳过
//   foodart <输出目录> --force 番茄      重新生成

@main
struct FoodArt {
    static func main() async {
        var args = Array(CommandLine.arguments.dropFirst())
        guard let outputDir = args.first else {
            print("用法: foodart <输出目录> [--force] [食材名...]")
            exit(1)
        }
        args.removeFirst()
        let force = args.contains("--force")
        let wanted = Set(args.filter { $0 != "--force" })

        let creator: ImageCreator
        do {
            creator = try await ImageCreator()
        } catch {
            print("Image Playground 不可用：\(error)。请在系统设置里开启 Apple Intelligence。")
            exit(2)
        }
        let style: ImagePlaygroundStyle = creator.availableStyles.contains(.animation) ? .animation : creator.availableStyles[0]
        print("风格: \(style), 可用: \(creator.availableStyles)")

        let entries = foodArtCatalog.filter { wanted.isEmpty || wanted.contains($0.name) }
        var done = 0
        for entry in entries {
            let folder = URL(fileURLWithPath: outputDir).appendingPathComponent("food-\(entry.id).imageset")
            let file = folder.appendingPathComponent("food-\(entry.id).png")
            if !force, FileManager.default.fileExists(atPath: file.path) {
                print("跳过 \(entry.name)")
                continue
            }
            do {
                let prompt = "\(entry.prompt), centered, product photo, isolated on a plain white background, soft studio lighting"
                guard let image = try await generate(prompt: prompt, with: creator, style: style) else {
                    print("没生成出来 \(entry.name)")
                    continue
                }
                let cutout = try cutOut(image)
                let framed = squareFramed(cutout, size: 512)
                try write(framed, to: file, folder: folder, id: entry.id)
                done += 1
                print("✓ \(entry.name) → food-\(entry.id).png")
            } catch {
                print("✗ \(entry.name): \(error)")
            }
        }
        print("完成 \(done) 张")
    }

    static func generate(prompt: String, with creator: ImageCreator, style: ImagePlaygroundStyle) async throws -> CGImage? {
        let concepts: [ImagePlaygroundConcept] = [.text(prompt)]
        for try await created in creator.images(for: concepts, style: style, limit: 1) {
            return created.cgImage
        }
        return nil
    }

    /// 把主体从背景里抠出来，返回带透明通道、已裁到主体范围的图。
    static func cutOut(_ image: CGImage) throws -> CGImage {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: image)
        try handler.perform([request])
        guard let result = request.results?.first else {
            throw NSError(domain: "FoodArt", code: 1, userInfo: [NSLocalizedDescriptionKey: "没找到前景"])
        }
        let buffer = try result.generateMaskedImage(ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: true)
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        guard let cg = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw NSError(domain: "FoodArt", code: 2, userInfo: [NSLocalizedDescriptionKey: "转不成 CGImage"])
        }
        return cg
    }

    /// 放进正方形画布，留一点边。
    static func squareFramed(_ image: CGImage, size: Int) -> CGImage {
        let scale = Double(size) * 0.88 / Double(max(image.width, image.height))
        let w = Double(image.width) * scale
        let h = Double(image.height) * scale
        let context = CGContext(
            data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: (Double(size) - w) / 2, y: (Double(size) - h) / 2, width: w, height: h))
        return context.makeImage()!
    }

    static func write(_ image: CGImage, to file: URL, folder: URL, id: String) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        guard let destination = CGImageDestinationCreateWithURL(file as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw NSError(domain: "FoodArt", code: 3, userInfo: [NSLocalizedDescriptionKey: "写不了 PNG"])
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        let contents = """
        {
          "images" : [ { "filename" : "food-\(id).png", "idiom" : "universal", "scale" : "1x" }, { "idiom" : "universal", "scale" : "2x" }, { "idiom" : "universal", "scale" : "3x" } ],
          "info" : { "author" : "xcode", "version" : 1 },
          "properties" : { "preserves-vector-representation" : false }
        }

        """
        try contents.write(to: folder.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
    }
}
