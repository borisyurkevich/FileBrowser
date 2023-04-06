//
//  SupportedFileType.swift
//  FileBrowser
//
//  Created by Boris Yurkevich on 06/04/2023.
//

import Foundation

enum SupportedFileType: String {

    case plainText = "public.plain-text"
    case markdown = "net.daringfireball.markdown"

    var fileExtension: String {
        switch self {
        case .plainText:
            return "txt"
        case .markdown:
            return "md"
        }
    }

    static func isSupported(extension: String) {
        return
    }
}
