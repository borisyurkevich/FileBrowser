//
//  ContentView.swift
//  FileBrowser
//
//  Created by Boris Yurkevich on 06/02/2023.
//

import SwiftUI
import OSLog

enum ContentViewState {
    case empty
    case loaded(OSDocument)
}

struct ContentView: View {

    @EnvironmentObject var appModel: AppModel

    @State private var folderName: String = "Select Folder"
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State var selection: URL?
    @State private var state = ContentViewState.empty

    private let logger = Logger(subsystem: "com.cocoaproductions.filebrowser", category: "content")

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Image(systemName: "folder")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text(appModel.url?.lastPathComponent ?? "")
            Button {
                selectFolder()
            } label: {
                Text("Select Folder")
            }
            Text(appModel.url?.absoluteString ?? "?")
        } content: {
            if appModel.allDocuments.isEmpty {
                Text("List of files")
            } else {
                List(selection: $selection) {
                    ForEach(appModel.allDocuments) { file in
                        process(document: file)
                    }
                }
            }
        } detail: {
            switch state {
            case .loaded(let doc):
                EditorView(document: doc)
            default:
                Text("Select a file")
            }
        }
        .task {
            appModel.getAccess()
        }
        .onChange(of: selection) { newSelection in
            if let newSelection {
                Task {
                    await selectFile(fileURL: newSelection)
                }
            } else {
                state  = .empty
            }
        }
    }

    func selectFolder() {
        if let vault = showOpenFolderPanel(directory: nil) {
            appModel.saveAccess(url: vault)
        }

    }

    func selectFile(fileURL: URL) async {

        switch state {
        case .loaded(let currentFile):
            currentFile.close()
            logger.log("Close file")
        default:
            break
        }

        state = .empty

        if let file = appModel.allDocuments.first(where: { $0.fileURL == fileURL }) {
            let success = await file.open()

            guard success else {
                logger.error("Failed to open")
                return
            }

            Task {
                await MainActor.run {
                    state = .loaded(file)
                }
            }
        }
    }

    private func showOpenFolderPanel(directory: URL?) -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        if let directory = directory {
            openPanel.directoryURL = directory
        }
        let response = openPanel.runModal()
        return response == .OK ? openPanel.url : nil
    }

    private func process(document: OSDocument) -> some View {
        makeLabelView(document: document)
    }

    private func makeLabelView(document: OSDocument, isFolder: Bool = false) -> some View {
        Label {
            Text(document.displayName)
                .padding(.leading, 8)
        } icon: {
            Image(systemName: "chart.bar.doc.horizontal")
                .padding(.leading, 8)

        }
        .onTapGesture {
            Task {
                await MainActor.run() {
                    selection = document.fileURL
                }
            }
        }
    }
}
