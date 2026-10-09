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
        if args.first == "--import" {
            // foodart --import <incoming 目录> <输出目录>：处理人工生成好的图。
            guard args.count >= 3 else {
                print("用法: foodart --import <incoming目录> <输出目录>")
                exit(1)
            }
            importImages(from: URL(fileURLWithPath: args[1]), to: URL(fileURLWithPath: args[2]))
            return
        }
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

    /// 人工生成的图：`food-<id>.png` 单张，或 `grid-NN.png` 四宫格（按目录顺序每四样一组）。
    /// 已经是透明背景的只裁切缩放，白底的用 Vision 抠。
    static func importImages(from incoming: URL, to outputDir: URL) {
        let files = ((try? FileManager.default.contentsOfDirectory(at: incoming, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension.lowercased() == "png" || $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "jpeg" || $0.pathExtension.lowercased() == "webp" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        var done = 0
        for file in files {
            let base = file.deletingPathExtension().lastPathComponent
            guard let source = loadImage(file) else {
                print("✗ 读不了 \(file.lastPathComponent)")
                continue
            }
            if base.hasPrefix("grid-"), let number = Int(base.dropFirst(5)) {
                let group = Array(foodArtCatalog.dropFirst((number - 1) * 4).prefix(4))
                let cells = quadrants(of: source)
                for (entry, cell) in zip(group, cells) {
                    do {
                        try process(cell, id: entry.id, outputDir: outputDir)
                        done += 1
                        print("✓ \(entry.name) ← \(file.lastPathComponent)")
                    } catch {
                        print("✗ \(entry.name): \(error)")
                    }
                }
            } else if base.hasPrefix("food-") {
                let id = String(base.dropFirst(5))
                guard foodArtCatalog.contains(where: { $0.id == id }) else {
                    print("? 目录里没有 \(id)，跳过")
                    continue
                }
                do {
                    try process(source, id: id, outputDir: outputDir)
                    done += 1
                    print("✓ \(id)")
                } catch {
                    print("✗ \(id): \(error)")
                }
            } else {
                print("? 不认识的文件名 \(file.lastPathComponent)")
            }
        }
        print("完成 \(done) 张")
    }

    static func process(_ image: CGImage, id: String, outputDir: URL) throws {
        let cutout = hasTransparentCorners(image) ? trimTransparent(image) : try cutOut(image)
        let framed = squareFramed(cutout, size: 512)
        let folder = outputDir.appendingPathComponent("food-\(id).imageset")
        try write(framed, to: folder.appendingPathComponent("food-\(id).png"), folder: folder, id: id)
    }

    static func loadImage(_ url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    static func quadrants(of image: CGImage) -> [CGImage] {
        let w = image.width / 2, h = image.height / 2
        let rects = [CGRect(x: 0, y: 0, width: w, height: h), CGRect(x: w, y: 0, width: w, height: h),
                     CGRect(x: 0, y: h, width: w, height: h), CGRect(x: w, y: h, width: w, height: h)]
        return rects.compactMap { image.cropping(to: $0) }
    }

    /// 四个角都是透明的，就当它已经抠好了。
    static func hasTransparentCorners(_ image: CGImage) -> Bool {
        guard image.alphaInfo != .none, image.alphaInfo != .noneSkipLast, image.alphaInfo != .noneSkipFirst else { return false }
        let ci = CIImage(cgImage: image)
        let context = CIContext()
        var buffer = [UInt8](repeating: 0, count: 4)
        let points = [CGPoint(x: 1, y: 1), CGPoint(x: image.width - 2, y: 1), CGPoint(x: 1, y: image.height - 2), CGPoint(x: image.width - 2, y: image.height - 2)]
        for point in points {
            context.render(ci, toBitmap: &buffer, rowBytes: 4, bounds: CGRect(x: point.x, y: point.y, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB))
            if buffer[3] > 8 { return false }
        }
        return true
    }

    /// 裁掉四周的透明边。
    static func trimTransparent(_ image: CGImage) -> CGImage {
        let width = image.width, height = image.height
        var data = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return image }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var minX = width, minY = height, maxX = 0, maxY = 0
        for y in 0..<height {
            for x in 0..<width where data[(y * width + x) * 4 + 3] > 8 {
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX > minX, maxY > minY else { return image }
        // CGContext 的 y 轴朝上，裁切用的 CGRect 是朝下的，翻一下。
        let rect = CGRect(x: minX, y: height - 1 - maxY, width: maxX - minX + 1, height: maxY - minY + 1)
        return image.cropping(to: rect) ?? image
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

    /// 按内容的轮廓裁，长边缩到 `size`，四周留 3% 的边。保留宽高比，瓶子就是细高的，面包就是扁的。
    static func squareFramed(_ image: CGImage, size: Int) -> CGImage {
        let longest = Double(max(image.width, image.height))
        let scale = Double(size) * 0.94 / longest
        let w = Double(image.width) * scale
        let h = Double(image.height) * scale
        let pad = Double(size) * 0.03
        let canvasW = Int((w + pad * 2).rounded(.up))
        let canvasH = Int((h + pad * 2).rounded(.up))
        let context = CGContext(
            data: nil, width: canvasW, height: canvasH, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: pad, y: pad, width: w, height: h))
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
