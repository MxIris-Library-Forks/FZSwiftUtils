//
//  FileType.swift
//
//
//  Created by Florian Zand on 10.03.23.
//

import Foundation

#if canImport(UniformTypeIdentifiers)
    import UniformTypeIdentifiers
#endif

#if canImport(UIKit)
    import MobileCoreServices
#endif

public extension URL {
    /// The file type of the url.
    var fileType: FileType? {
        FileType(url: self)
    }

    /// A Boolean value indicating whether the file is a video.
    var isVideo: Bool {
        fileType == .video
    }

    /// A Boolean value indicating whether the file is an image.
    var isImage: Bool {
        fileType == .image
    }

    /// A Boolean value indicating whether the file is a GIF.
    var isGIF: Bool {
        fileType == .gif
    }

    /// A Boolean value indicating whether the file is a multimedia file (audio, image, GIF or video).
    var isMultimedia: Bool {
        fileType?.isMultimedia ?? false
    }
}


/// The type of a file.
public enum FileType: Hashable, CustomStringConvertible, CaseIterable, Codable {
    /// Audio
    case audio
    /// Video
    case video
    /// Image
    case image
    /// PDF
    case pdf
    /// Document
    case document
    /// Spreadsheet
    case spreadsheet
    /// Presentation
    case presentation
    /// Text
    case text
    /// Archive
    case archive
    /// Alias
    case aliasFile
    /// Symbolic Link
    case symbolicLink
    /// Folder
    case folder
    /// Application
    case application
    /// Executable
    case executable
    /// Disk image
    case diskImage
    /// Font
    case font
    /// Contact
    case contact
    /// Calendar event
    case calendar
    /// Source Code
    case sourceCode
    /// GIF
    case gif
    /// Other
    case other(fileExtension: String, identifier: String?)

    /// Returns the type for the file at the specified url.
    public init?(url: URL) {
        if url.pathExtension != "" || url.hasDirectoryPath, let fileType = FileType(fileExtension: url.pathExtension) {
            self = fileType
        } else if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
            if let contentType = url.contentType, let fileType = FileType.allCases.first(where: { $0.identifier == contentType.identifier }) ?? FileType.allCases.first(where: { contentType.conforms(to: $0.contentType!) }) {
                self = fileType
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    /// Returns the type for the specified file extension.
    public init?(fileExtension: String) {
        let fileExtension = fileExtension.lowercased()
        if fileExtension == "" {
            self = .folder
        } else if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
            if let contentType = UTType(filenameExtension: fileExtension), let fileType = FileType(contentType: contentType) {
                self = fileType
            } else {
                return nil
            }
        } else if let fileType = FileType.allCases.first(where: { $0.commonExtensions.contains(fileExtension) }) {
            self = fileType
        } else {
            return nil
        }
    }

    /// Returns the type for the specified content type.
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    public init?(contentType: UTType) {
        if let fileType = FileType.allCases.first(where: { $0.identifier == contentType.identifier || contentType.conforms(to: $0.contentType!)}) {
            self = fileType
        } else if let fileExtension = contentType.preferredFilenameExtension {
            self = FileType.allCases.first(where: {$0.commonExtensions.contains(fileExtension)}) ?? .other(fileExtension: fileExtension, identifier: contentType.identifier)
        } else {
            return nil
        }
    }
}

@available(macOS, deprecated: 11.0, message: "Use contentType instead")
@available(iOS, deprecated: 14.0, message: "Use contentType instead")
@available(macCatalyst, deprecated: 14.0, message: "Use contentType instead")
@available(tvOS, deprecated: 14.0, message: "Use contentType instead")
@available(watchOS, deprecated: 7.0, message: "Use contentType instead")
public extension FileType {
    /// Returns the type for the specified content type identifier.
    init?(contentTypeIdentifier: String) {
        if let fileType = FileType.allCases.first(where: { $0.identifier == contentTypeIdentifier }) {
            self = fileType
        } else {
            return nil
        }
    }

    /// Returns the type for the specified content type tree.
    init?(contentTypeTree: [String]) {
        if let fileType = contentTypeTree.lazy.compactMap({ FileType(contentTypeIdentifier: $0) }).first {
            self = fileType
        } else {
            return nil
        }
    }
}

public extension FileType {
    /// The content type identifier of the file type.
    var identifier: String? {
        switch self {
        case .aliasFile: return "com.apple.alias-file"
        case .symbolicLink: return "public.symlink"
        case .folder: return "public.folder"
        case .application: return "com.apple.application"
        case .archive: return "public.archive"
        case .spreadsheet: return "public.spreadsheet"
        case .audio: return "public.audio"
        case .calendar: return "public.calendar-event"
        case .contact: return "public.contact"
        case .diskImage: return "public.disk-image"
        case .executable: return "public.executable"
        case .font: return "public.font"
        case .video: return "public.movie"
        case .gif: return "com.compuserve.gif"
        case .image: return "public.image"
        case .pdf: return "com.adobe.pdf"
        case .presentation: return "public.presentation"
        case .text: return "public.text"
        case .document: return "public.composite-content"
        case .sourceCode: return "public.source-code"
        case .other(_, let identifier): return identifier
        }
    }
    
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    /// The content type of the file type.
    var contentType: UTType? {
        if let identifier = identifier {
            return UTType(identifier)
        }
        return nil
    }

    /// The most common file extensions of the file type.
    var commonExtensions: [String] {
        switch self {
        case .image:
            return ["jpg", "jpeg", "png", "heic", "tiff", "heif", "tif", "webp", "svg", "ico", "raw"]
        case .video:
            return ["mp4", "mov", "m4v", "avi", "mkv", "wmv", "flv", "webm", "ts", "mpeg", "mpg", "qt", "gifv", "m2ts", "mts", "3gp", "3g2", "mxf"]
        case .gif:
            return ["gif"]
        case .audio:
            return ["mp3", "m4a", "aac", "wav", "flac", "alac", "ogg", "aiff", "wma", "oga", "mka", "wave", "opus", "amr"]
        case .pdf:
            return ["pdf"]
        case .text:
            return ["txt", "md", "csv", "rtf", "log", "tex"]
        case .archive:
            return ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "lzma", "cab", "tgz"]
        case .document:
            return ["docx", "doc", "pages", "odt", "rtf", "word", "txt", "xml", "md"]
        case .spreadsheet:
            return ["xlsx", "xls", "ods", "csv", "tsv", "xlsm", "xlsb"]
        case .presentation:
            return ["pptx", "powerpoint", "keynote", "odp", "ppt", "prezi"]
        case .application:
            return ["app", "exe", "apk", "bat", "msi"]
        case .diskImage:
            return ["iso", "dmg", "vmdk", "vhd", "img"]
        case .executable:
            return ["exe", "sh", "bat", "com", "bin"]
        case .calendar:
            return ["ics", "ifb"]
        case .contact:
            return ["vcf", "vcard", "abbu"]
        case .font:
            return ["ttf", "otf", "woff", "woff2", "eot", "pfb", "pfm"]
        case .sourceCode:
            return ["js", "py", "rb", "pl", "php", "java", "swift", "c", "cpp", "cs"]
        case .other(let pathExtension,_): return [pathExtension]
        default:
            return []
        }
    }

    /// The description of the file type.
    var description: String {
        switch self {
        case .aliasFile: return "AliasFile"
        case .application: return "Application"
        case .archive: return "Archive"
        case .audio: return "Audio"
        case .calendar: return "Calendar"
        case .contact: return "Contact"
        case .diskImage: return "DiskImage"
        case .document: return "Document"
        case .spreadsheet: return "Spreadsheet"
        case .executable: return "Executable"
        case .font: return "Font"
        case .folder: return "Folder"
        case .gif: return "GIF"
        case .image: return "Image"
        case .pdf: return "PDF"
        case .presentation: return "Presentation"
        case .symbolicLink: return "SymbolicLink"
        case .text: return "Text"
        case .video: return "Video"
        case .sourceCode: return "Source Code"
        case .other(let pathExtension, let identifier): return identifier != nil ? "other(\(identifier!))" : "other(.\(pathExtension))"
        }
    }

    /// A Boolean value indicating whether the file type is a multimedia type (either `audio`, `video`, `image` or `gif`).
    var isMultimedia: Bool {
        Self.multimediaTypes.contains(self)
    }
    
    /// A Boolean value indicating whether the file type is an image type (either `image` or `gif`).
    var isImageType: Bool {
        Self.imageTypes.contains(self)
    }

    /// All file types.
    static let allCases: [FileType] = [.audio, .video, .gif, .image, .pdf, .document, .spreadsheet, .presentation, .text, .archive, .aliasFile, .symbolicLink, .folder, .application, .executable, .diskImage, .font, .contact, .calendar, .sourceCode]

    /// All multimedia file types (`audio`, `video`, `image` and `gif`).
    static var multimediaTypes: [FileType] = [.gif, .image, .video, .audio]

    /// All image file types (`image` and `gif`).
    static var imageTypes: [FileType] = [.gif, .image]
}
