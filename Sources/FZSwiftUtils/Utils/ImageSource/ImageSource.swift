//
//  ImageSource.swift
//
//
//  Created by Florian Zand on 02.06.22.
//

import Foundation
import ImageIO
import simd
import UniformTypeIdentifiers

public class ImageSource {
    public let cgImageSource: CGImageSource

    /// The type identifier of the image source.
    public var typeIdentifier: String? {
        CGImageSourceGetType(cgImageSource) as String?
    }

    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    /// The UTType of the image source.
    public var utType: UTType? {
        guard let typeIdentifier = typeIdentifier else { return nil }
        return UTType(typeIdentifier)
    }

    /// The number of images of the images included in the image source.
    public var count: Int {
        CGImageSourceGetCount(cgImageSource)
    }

    /// The current status of the image source.
    public var status: CGImageSourceStatus {
        CGImageSourceGetStatus(cgImageSource)
    }

    /// Returns the current status of an image at the specified index in the image source.
    public func status(at index: Int) -> CGImageSourceStatus {
        CGImageSourceGetStatusAtIndex(cgImageSource, index)
    }

    /// Returns the index of the primary image for an HEIF image, or 0 for any other image format.
    public var primaryImageIndex: Int {
        CGImageSourceGetPrimaryImageIndex(cgImageSource)
    }

    /**
     Returns the properties of the image source.

     These properties apply to the container in general but not necessarily to any individual image contained in the image source.
     */
    public func properties() -> ImageProperties? {
        let rawValue = CGImageSourceCopyProperties(cgImageSource, nil) as? [String: Any] ?? [:]
        return rawValue.toModel(ImageProperties.self, decoder: ImageProperties.decoder)
    }

    /**
     Returns the properties of an image at the specified index in the image source.
     */
    public func properties(at index: Int) -> ImageProperties? {
        let rawValue = CGImageSourceCopyPropertiesAtIndex(cgImageSource, index, nil) as? [String: Any] ?? [:]
        return rawValue.toModel(ImageProperties.self, decoder: ImageProperties.decoder)
    }

    /**
     Returns the image at the specified index in the image source.

     - Parameters:
        - index: The zero-based index of the image you want. If the index is invalid, this method returns `nil.
        - options: Additional image creation options

     - Returns: The image at the specified index, or `nil` if an error occurs.
     */
    public func getImage(at index: Int = 0, options: ImageOptions? = .init()) -> CGImage? {
        CGImageSourceCreateImageAtIndex(cgImageSource, index, options?.dic)
    }

    /**
     Returns the image at the specified index in the image source asynchronously.

     - Parameters:
        - index: The zero-based index of the image you want. If the index is invalid, this method returns `nil.
        - options: Additional image creation options

     - Returns: The image at the specified index, or `nil` if an error occurs.
     */
    public func image(at index: Int = 0, options: ImageOptions? = .init()) async -> CGImage? {
        await withCheckedContinuation { continuation in
            image(at: index, options: options) { image in
                continuation.resume(returning: image)
            }
        }
    }

    /**
     Returns the image at the specified index in the image source asynchronously.

     - Parameters:
        - index: The zero-based index of the image you want. If the index is invalid, this method returns `nil.
        - options: Additional image creation options
        - completionHandler: A closure the method calls on completion which returns the image at the specified index, or `nil` if an error occurs.
     */
    public func image(at index: Int = 0, options: ImageOptions? = .init(), completionHandler: @escaping (CGImage?) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            let image = CGImageSourceCreateImageAtIndex(self.cgImageSource, index, options?.dic)
            completionHandler(image)
        }
    }

    /**
     Returns the thumbnail at the specified index in the image source.

     - Parameters:
        - index: The zero-based index of the thumbnail you want. If the index is invalid, this method returns `nil`.
        - options: Additional thumbnail creation options

     - Returns: The thumbnail at the specified index, or `nil` if an error occurs.
     */
    public func getThumbnail(at index: Int = 0, options: ThumbnailOptions? = .init()) -> CGImage? {
        CGImageSourceCreateThumbnailAtIndex(cgImageSource, index, options?.toDictionary().cfDictionary)
    }

    /**
     Returns the thumbnail at the specified index in the image source asynchronously.

     - Parameters:
        - index: The zero-based index of the thumbnail you want. If the index is invalid, this method returns `nil`.
        - options: Additional thumbnail creation options

     - Returns: The thumbnail at the specified index, or `nil` if an error occurs.
     */
    public func thumbnail(at index: Int = 0, options: ThumbnailOptions? = .init()) async -> CGImage? {
        await withCheckedContinuation { continuation in
            thumbnail(at: index, options: options) { image in
                continuation.resume(returning: image)
            }
        }
    }

    /**
     Returns the thumbnail at the specified index in the image source asynchronously.

     - Parameters:
        - index: The zero-based index of the thumbnail you want. If the index is invalid, this method returns `nil.
        - options: Additional thumbnail creation options
        - completionHandler: A closure the method calls on completion which returns the thumbnail at the specified index, or `nil` if an error occurs.
     */
    public func thumbnail(at index: Int = 0, options: ThumbnailOptions? = .init(), completionHandler: @escaping (CGImage?) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            let image = CGImageSourceCreateThumbnailAtIndex(self.cgImageSource, index, options?.toDictionary().cfDictionary)
            completionHandler(image)
        }
    }
    
    /// The images of the image source asynchronously.
    public func images(options: ImageOptions? = .init()) -> ImageSequence {
        ImageSequence(source: self, type: .image, imageOptions: options)
    }
    
    /// The images of the image source.
    public func getImages(options: ImageOptions? = .init()) -> [CGImage] {
        (try? images(options: options).collect()) ?? []
    }

    /// The thumbnails of the image source asynchronously.
    public func thumbnails(options: ThumbnailOptions? = .init()) -> ImageSequence {
        ImageSequence(source: self, type: .thumbnail, thumbnailOptions: options)
    }
    
    /// The thumbnails of the image source.
    public func getThumbnails(options: ThumbnailOptions? = .init()) -> [CGImage] {
        (try? thumbnails(options: options).collect()) ?? []
    }

    /// The image frames of the image source asynchronously.
    public func imageFrames(options: ImageOptions? = .init()) -> ImageFrameSequence {
        ImageFrameSequence(source: self, type: .image, imageOptions: options)
    }
    
    /// The image frames of the image source.
    public func getImageFrames(options: ImageOptions? = .init()) -> [CGImageFrame] {
        (try? imageFrames(options: options).collect()) ?? []
    }

    /// The thumbnail frames of the image source asynchronously.
    public func thumbnailFrames(options: ThumbnailOptions? = .init()) -> ImageFrameSequence {
        ImageFrameSequence(source: self, type: .thumbnail, thumbnailOptions: options)
    }
    
    /// The thumbnail frames of the image source.
    public func getThumbnailFrames(options: ThumbnailOptions? = .init()) -> [CGImageFrame] {
        (try? thumbnailFrames(options: options).collect()) ?? []
    }

    /**
     Creates an image source that reads from a CGImageSource.

     - Parameters:
        - cgImageSource: The CGImageSource of the image.
     */
    public init(_ cgImageSource: CGImageSource) {
        self.cgImageSource = cgImageSource
    }

    /**
     Creates an image source that reads from a location specified by a URL.

     - Parameters:
        - url: The URL of the image.
     */
    public convenience init?(url: URL) {
        guard let cgImageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        self.init(cgImageSource)
    }

    /**
     Creates an image source that reads from a location specified by a file path.

     - Parameters:
        - path: The file path of the image.
     */
    public convenience init?(path: String) {
        self.init(url: URL(fileURLWithPath: path))
    }

    /**
     Creates an image source that reads from data.

     - Parameters:
        - data: The data of the image.
     */
    public convenience init?(data: Data) {
        guard let cgImageSource = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        self.init(cgImageSource)
    }
}

extension ImageSource: CustomStringConvertible {
    /// A string representation of the image source.
    public var description: String {
        "ImageSource[\(ObjectIdentifier(self))"
    }
}

extension ImageSource: Equatable {
    public static func == (lhs: ImageSource, rhs: ImageSource) -> Bool {
        lhs.cgImageSource == rhs.cgImageSource
    }
}

public extension ImageSource {
    /// Returns if the image source is animated (e.g. GIF)
    var isAnimated: Bool {
        if count > 1, properties(at: 0)?.delayTime != nil {
            return true
        }
        return false
    }

    /// Returns if the image source is animatable (contains several images)
    var isAnimatable: Bool {
        if count > 1 {
            return true
        }
        return false
    }

    /// The pixel size of the image source.
    var pixelSize: CGSize? {
        properties(at: 0)?.pixelSize
    }

    private static let defaultFrameRate: Double = 15.0

    /// The default image frame duration for animating in seconds.
    static let defaultFrameDuration: Double = 1 / defaultFrameRate

    /**
     The total animation duration of an image source that is animated.,

     Returns `nil` if the image isn't animated.
     */
    var animationDuration: Double? {
        guard count > 1 else { return nil }
        let totalDuration = (0 ..< count).reduce(0) { $0 + (self.properties(at: $1)?.delayTime ?? 0.0) }
        return (totalDuration != 0.0) ? totalDuration : nil
    }
}

extension ImageSource {
    enum Error: Int32, Swift.Error {
        case failedThumbnailCreate
        case failedImageCreate
        case unexpectedEOF = -5
        case invalidData = -4
        case unknownType = -3
        case incomplete = -1
    }
}

#if os(macOS)
    import AppKit
    public extension ImageSource {
        /**
         Creates an image source that reads from a `NSImage`.
         
         - Note: Loading an animated image takes time as each image frame is loaded initially. It's recommended to either use the url to the image if available, or parse the animation properties and frames via the image's `NSBitmapImageRep` representation.

         - Parameters:
            - image: The `NSImage` object.
         */
        convenience init?(image: NSImage) {
            let images = image.representations.compactMap({$0 as? NSBitmapImageRep}).flatMap({$0.getImages()})
            guard !images.isEmpty else { return nil }
            let types = Set(images.compactMap { $0.utType })
            let outputType = types.count == 1 ? (types.first ?? kUTTypeTIFF) : kUTTypeTIFF
            guard let mutableData = CFDataCreateMutable(nil, 0), let destination = CGImageDestinationCreateWithData(mutableData, outputType, images.count, nil) else { return nil }
            images.forEach { CGImageDestinationAddImage(destination, $0, nil) }
            guard CGImageDestinationFinalize(destination) else { return nil }
            guard let cgImageSource = CGImageSourceCreateWithData(mutableData, nil) else { return nil }
            self.init(cgImageSource)
        }
    }

#endif

#if canImport(UIKit)
    import UIKit
    public extension ImageSource {
        /**
         Creates an image source that reads from a `UIImage`.

         - Parameters:
            - image: The `UIImage` object.
         */
        convenience init?(image: UIImage) {
            guard let data = image.pngData() else { return nil }
            self.init(data: data)
        }
    }
#endif

public extension ImageSource {
    // The set of status values for images and image sources.
    enum Status: CustomStringConvertible {
        /// The end of the file occurred unexpectedly.
        case unexpectedEOF
        /// The data is not valid.
        case invalidData
        /// The image is an unknown type.
        case unknownType
        ///  The image source is reading the header.
        case readingHeader
        /// The operation is not complete
        case incomplete
        /// The operation is complete.
        case complete
        /// Some other status.
        case other(CGImageSourceStatus)
        init(_ status: CGImageSourceStatus) {
            switch status {
            case .statusUnexpectedEOF:
                self = .unexpectedEOF
            case .statusInvalidData:
                self = .invalidData
            case .statusUnknownType:
                self = .unknownType
            case .statusReadingHeader:
                self = .readingHeader
            case .statusIncomplete:
                self = .incomplete
            case .statusComplete:
                self = .complete
            @unknown default:
                self = .other(status)
            }
        }

        public var description: String {
            switch self {
            case .unexpectedEOF: return "Unexpected EOF"
            case .invalidData: return "Invalid Data"
            case .unknownType: return "Unknown Type"
            case .readingHeader: return "Reading Header"
            case .incomplete: return "Incomplete"
            case .complete: return "Complete"
            case let .other(status): return "CGImageSourceStatus: \(status.rawValue)"
            }
        }
    }
}
