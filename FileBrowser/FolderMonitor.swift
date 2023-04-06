//
//  FolderMonitor.swift
//  FileBrowser
//
//  Created by Boris Yurkevich on 02/03/2023.
//

import Foundation

class FolderMonitor {
    // MARK: Properties

    /// A file descriptor for the monitored directory.
    private var monitoredFolderFileDescriptor: CInt = -1
    /// A dispatch queue used for sending file changes in the directory.
    private let folderMonitorQueue: DispatchQueue
    /// A dispatch source to monitor a file descriptor created from the directory.
    private var folderMonitorSource: DispatchSourceFileSystemObject?

    /// URL for the directory being monitored.
    var url: Foundation.URL

    var folderDidChange: ((Date) -> Void)?
    // MARK: Initializers
    init(url: Foundation.URL) {
        self.url = url
        folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)
    }

    deinit {
        self.stopMonitoring()
    }

    // MARK: Monitoring
    /// Listen for changes to the directory (if we are not already).
    func startMonitoring() {
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
        }
        // Open the directory referenced by URL for monitoring only.
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)

        guard monitoredFolderFileDescriptor != -1 else {
            return
        }

        // Define a dispatch source monitoring the directory for additions, deletions, and renamings.
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: monitoredFolderFileDescriptor, eventMask: .write,
            queue: folderMonitorQueue)
        // Define the block to call when a file change is detected.
        folderMonitorSource?.setEventHandler { [weak self] in
            guard let strongSelf = self else { return }
            guard
                let attributes = try? FileManager.default.attributesOfItem(
                    atPath: strongSelf.url.path)
            else { return }
            if let lastModified = attributes[.modificationDate] as? Date {
                strongSelf.folderDidChange?(lastModified)
            }
        }
        // Define a cancel handler to ensure the directory is closed when the source is cancelled.
        folderMonitorSource?.setCancelHandler { [weak self] in
            guard let strongSelf = self else { return }
            close(strongSelf.monitoredFolderFileDescriptor)
            strongSelf.monitoredFolderFileDescriptor = -1
            strongSelf.folderMonitorSource = nil
        }
        // Start monitoring the directory via the source.
        folderMonitorSource?.resume()
    }
    /// Stop listening for changes to the directory, if the source has been created.
    func stopMonitoring() {
        folderMonitorSource?.cancel()
    }
}
