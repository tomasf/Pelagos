#if canImport(CoreGraphics) && canImport(ImageIO) && canImport(UniformTypeIdentifiers)
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation
import Pelagos

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
let inputDirectory = "/Users/tomasf/Desktop/SVG test suite"

do {
    let fileManager = FileManager.default
    let inputURL = URL(fileURLWithPath: inputDirectory)
    let outputDirectory = "/Users/tomasf/Desktop/SVG output"
    let outputURL = URL(fileURLWithPath: outputDirectory)
    try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)

    let svgFiles = try fileManager.contentsOfDirectory(at: inputURL, includingPropertiesForKeys: nil)
        .filter { $0.pathExtension.lowercased() == "svg" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

    for fileURL in svgFiles {
        let svg = try SVGParser().parse(url: fileURL)

        let size = svg.size ?? (width: 512, height: 512)
        let width = size.width
        let height = size.height

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            fatalError("Failed to create bitmap context.")
        }

        renderSVG(svg, in: context, size: size, fillBackground: true)

        guard let image = context.makeImage() else {
            fatalError("Failed to create CGImage.")
        }

        let outputFile = outputURL.appendingPathComponent(fileURL.deletingPathExtension().lastPathComponent + ".png")
        let url = outputFile as CFURL
        guard let destination = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil) else {
            fatalError("Failed to create PNG destination.")
        }
        CGImageDestinationAddImage(destination, image, nil)
        if !CGImageDestinationFinalize(destination) {
            fatalError("Failed to write PNG.")
        }

        print("Wrote PNG to \(outputFile.path)")

        var mediaBox = CGRect(x: 0, y: 0, width: width, height: height)
        let pdfFile = outputURL.appendingPathComponent(fileURL.deletingPathExtension().lastPathComponent + ".pdf")
        guard let pdfContext = CGContext(pdfFile as CFURL, mediaBox: &mediaBox, nil) else {
            fatalError("Failed to create PDF context.")
        }
        pdfContext.beginPDFPage(nil as CFDictionary?)
        renderSVG(svg, in: pdfContext, size: size, fillBackground: false)
        pdfContext.endPDFPage()
        pdfContext.closePDF()

        print("Wrote PDF to \(pdfFile.path)")
    }
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
#else
fputs("PelagosCLI only supports Apple platforms.\n", stderr)
exit(1)
#endif
#else
fputs("PelagosCLI requires CoreGraphics and ImageIO.\n", stderr)
exit(1)
#endif

private func renderSVG(
    _ svg: SVG,
    in context: CGContext,
    size: (width: Double, height: Double),
    fillBackground: Bool
) {
    if fillBackground {
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
    }

    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1, y: -1)

    if let viewBox = svg.viewBox {
        applyViewBoxTransform(
            context: context,
            viewBox: viewBox,
            outputWidth: size.width,
            outputHeight: size.height,
            preserveAspectRatio: svg.preserveAspectRatio
        )
    }

    svg.render(to: context)
}

private func applyViewBoxTransform(
    context: CGContext,
    viewBox: ViewBox,
    outputWidth: Double,
    outputHeight: Double,
    preserveAspectRatio: PreserveAspectRatio?
) {
    let scaleX = outputWidth / viewBox.width
    let scaleY = outputHeight / viewBox.height
    let alignment = preserveAspectRatio?.alignment ?? .xMidYMid
    let meetOrSlice = preserveAspectRatio?.meetOrSlice ?? .meet

    if alignment == .none {
        context.scaleBy(x: scaleX, y: scaleY)
        context.translateBy(x: -viewBox.minX, y: -viewBox.minY)
        return
    }

    let scale = meetOrSlice == .slice ? max(scaleX, scaleY) : min(scaleX, scaleY)
    let scaledWidth = viewBox.width * scale
    let scaledHeight = viewBox.height * scale

    let offsetX = alignmentOffset(
        alignment: alignment,
        start: 0,
        end: outputWidth - scaledWidth
    )
    let offsetY = alignmentOffset(
        alignment: alignment,
        start: 0,
        end: outputHeight - scaledHeight
    )

    context.translateBy(x: offsetX, y: offsetY)
    context.scaleBy(x: scale, y: scale)
    context.translateBy(x: -viewBox.minX, y: -viewBox.minY)
}

private func alignmentOffset(alignment: PreserveAspectRatio.Alignment, start: Double, end: Double) -> Double {
    switch alignment {
    case .xMinYMin, .xMinYMid, .xMinYMax:
        return start
    case .xMidYMin, .xMidYMid, .xMidYMax:
        return (start + end) / 2
    case .xMaxYMin, .xMaxYMid, .xMaxYMax:
        return end
    case .none:
        return start
    }
}
