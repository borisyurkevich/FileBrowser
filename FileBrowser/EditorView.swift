//
//  EditorView.swift
//  FileBrowser
//
//  Created by Boris Yurkevich on 03/03/2023.
//

import SwiftUI

struct EditorView: View {

    @EnvironmentObject var appModel: AppModel
    @State private var externalUpdate = false
    @State private var editorText: String

    private let document: OSDocument

    init(document: OSDocument) {
        self.document = document
        self.editorText = document.text
    }

    var body: some View {
        TextEditor(text: $editorText)
            .padding(.top, 8)
            .padding(.leading, 16)
            .background(Color(nsColor: .textBackgroundColor))
            .task {
                document.willSaveHandler = {
                    return editorText
                }
            }
            .onChange(of: editorText) { _ in
                save()
            }
    }

    func save() {
        guard externalUpdate == false else {
            self.externalUpdate = false
            return
        }
        document.updateChangeCount(.done)
        document.save(self)
        appModel.log(content: "Save")
    }
}

