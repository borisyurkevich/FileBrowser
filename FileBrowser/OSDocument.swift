//
//  OSDocument.swift
//  FileBrowser
//
//  Based on https://gist.github.com/nicklockwood/19569dc738b565c67f4d97302bf48697
//
//  Created by Boris Yurkevich on 06/02/2023.
//

import Foundation

import SwiftUI

enum OSDocumentError: Error {
    case unknownFileFormat
    case attemptedToReadDirectory
    case delegateIsNotSet
    case unableToSaveFile
    case forgotToSetSaveHandler
}

#if canImport(UIKit)

import UIKit

typealias OSApplicationDelegateAdaptor = UIApplicationDelegateAdaptor
typealias OSApplicationDelegate = UIApplicationDelegate
typealias OSLongPressGestureRecognizer = UILongPressGestureRecognizer
typealias OSTapGestureRecognizer = UITapGestureRecognizer
typealias OSWorkspace = UIApplication
typealias OSView = UIView
typealias OSColor = UIColor

extension UIResponder {
    var nextResponder: UIResponder? { next }
}

protocol OSViewRepresentable: UIViewRepresentable {
    associatedtype OSViewType: UIView

    func makeOSView(context: Context) -> OSViewType
    func updateOSView(_ osView: OSViewType, context: Context)
}

extension OSViewRepresentable {
    func makeUIView(context: Context) -> OSViewType {
        makeOSView(context: context)
    }

    func updateUIView(_ uiView: OSViewType, context: Context) {
        updateOSView(uiView, context: context)
    }
}

class OSDocument: UIDocument, Identifiable {

    let id: String

    func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {}
    func fileWrapper(ofType typeName: String) throws -> FileWrapper { fatalError() }

    private let logger = Logger(subsystem: "com.cocoaproductions.filebrowser", category: "document")

    init(id: String) {
        self.id = id

        super.init()
    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let fileWrapper = contents as? FileWrapper,
              fileWrapper.isDirectory
        else {
            throw OSDocumentError.unknownFileFormat
        }
        try read(from: fileWrapper, ofType: SupportedFileType.markdown.rawValue)
    }

    override func contents(forType typeName: String) throws -> Any {
        try fileWrapper(ofType: typeName)
    }

    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        logger.error("\(error)")
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
    }
}

#elseif canImport(AppKit)

import AppKit

typealias OSApplicationDelegateAdaptor = NSApplicationDelegateAdaptor
typealias OSApplicationDelegate = NSApplicationDelegate
typealias OSLongPressGestureRecognizer = NSPressGestureRecognizer
typealias OSTapGestureRecognizer = NSClickGestureRecognizer
typealias OSWorkspace = NSWorkspace
typealias OSView = NSView
typealias OSColor = NSColor

protocol OSViewRepresentable: NSViewRepresentable where NSViewType == OSViewType {
    associatedtype OSViewType: NSView

    func makeOSView(context: Context) -> OSViewType
    func updateOSView(_ osView: OSViewType, context: Context)
}

extension OSViewRepresentable {
    func makeNSView(context: Context) -> OSViewType {
        makeOSView(context: context)
    }

    func updateNSView(_ nsView: OSViewType, context: Context) {
        updateOSView(nsView, context: context)
    }
}

extension NSDocument {
    func open(_ completion: ((Bool) -> Void)?) {
        Task {
            let success = await open()
            completion?(success)
        }
    }

    func open() async -> Bool {
        guard let fileURL else {
            return false
        }
        do {
            try read(from: fileURL, ofType: SupportedFileType.markdown.rawValue)
            return true
        } catch {
            // TODO: Handle errors
            return false
        }
    }

    /// This function creates a backup copy of a file. It's not been used but can be useful.
    func autosave() {
        // TODO: handle errors
        autosave(withDelegate: nil, didAutosave: nil, contextInfo: nil)
    }
}

extension NSDocument.ChangeType {
    static let done = changeDone
}


final class OSDocument: NSDocument {

    var text = String()

    /// A handler for retrieving up-to-date text content from the parser.
    /// Called when the document is about to save.
    var willSaveHandler: (() -> String)?

    override class func isNativeType(_ name: String) -> Bool {
        return true
    }

    override class var autosavesInPlace: Bool { false }

    override func data(ofType typeName: String) throws -> Data {
        guard let willSave = willSaveHandler else {
            throw OSDocumentError.forgotToSetSaveHandler
        }
        text = willSave()

        guard let data = text.data(using: .utf8) else {
            throw OSDocumentError.unableToSaveFile
        }

        return data
    }

    override nonisolated func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        guard let contentData = fileWrapper.regularFileContents else {
            return
        }
        if let content = String(data: contentData, encoding: .utf8) {
            Task {
                await updateText(content)
            }
        }
    }

    // This enables asynchronous reading.
    override class func canConcurrentlyReadDocuments(ofType: String) -> Bool {
        return ofType == SupportedFileType.plainText.rawValue || ofType == SupportedFileType.markdown.rawValue
    }

    // MARK: - Private

    private func updateText(_ newText: String) async {
        await MainActor.run {
            text = newText
        }
    }
}

extension OSDocument: Identifiable {

    var id: URL {
        return fileURL!
    }
}

#endif
