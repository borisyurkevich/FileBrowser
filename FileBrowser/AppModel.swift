//
//  AppModel.swift
//  FileBrowser
//
//  Created by Boris Yurkevich on 06/02/2023.
//

import Foundation
import OSLog

final class AppModel: ObservableObject {

    /// Root folder URL
    @Published var url: URL?
    @Published var allDocuments: [OSDocument] = []

    private let logger = Logger(subsystem: "com.cocoaproductions.linkedit", category: "global")
    private var monitor: FolderMonitor?

    func saveAccess(url: URL) {
        // User picks new default folder, remove access to the previous folder
         self.url?.stopAccessingSecurityScopedResource()

        guard let dataToBeArchived = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) else {
            return
        }
        guard let archiveURL = archiveURL() else  {
            return
        }
        try? dataToBeArchived.write(to: archiveURL)

        self.url = url
    }

    func getAccess() {
        guard let archiveURL = archiveURL() else {
            return
        }
        guard let archivedData = try? Data(contentsOf: archiveURL) else {
            return
        }

        var isStale = false
        do {
            let newURL = try URL(resolvingBookmarkData: archivedData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            guard !isStale else {
                return
            }
            let result = newURL.startAccessingSecurityScopedResource()
            logger.debug("Start access \(result)")

            self.url = newURL
            allDocuments = loadSubfiles(root: newURL)
            startFolderMonitor()
        } catch {
            logger.error("\(error.localizedDescription)")
            return
        }
    }

    func loadSubfiles(root: URL) -> [OSDocument] {
        let fileManager = FileManager.default

        do {
            let files = try fileManager.contentsOfDirectory(at: root,
                                                            includingPropertiesForKeys: [],
                                                            options: [.producesRelativePathURLs, .skipsHiddenFiles])
            let documents: [OSDocument] =
            try files.compactMap { url in
                if url.pathExtension == SupportedFileType.plainText.fileExtension {
                    return try OSDocument(contentsOf: url, ofType: SupportedFileType.plainText.rawValue)
                } else if url.pathExtension == SupportedFileType.markdown.fileExtension {
                    return try OSDocument(contentsOf: url, ofType: SupportedFileType.markdown.rawValue)
                } else {
                    return nil
                }
            }

            return documents
        } catch {
            logger.error("\(error)")
        }

        return []
    }

    func startFolderMonitor() {
        guard let url = self.url else {
            return
        }
        monitor = FolderMonitor(url: url)
        monitor?.startMonitoring()
        monitor?.folderDidChange = { [weak self] change in
            guard let self = self else {
                return
            }
            logger.log("Folder update")
            self.updateFiles()
        }
    }

    func stopFolderMonitor() {
        monitor?.stopMonitoring()
    }

    func updateFiles() {
        guard let root = self.url else {
            return
        }
        let newDocuments = self.loadSubfiles(root: root)
        Task {
            await MainActor.run {
                self.allDocuments = newDocuments
            }
        }
    }

    func log(content: String) {
        logger.log("\(content)")
    }

    func handleError(content: String) {
        logger.error("\(content)")
    }

    // MARK: - Private

    private func archiveURL() -> URL? {
        guard let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        logger.debug("App data: \(documentURL.path)")
        return documentURL.appendingPathComponent("FileBrowser.data")
    }
}
