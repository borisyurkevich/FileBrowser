//
//  FileBrowserApp.swift
//  FileBrowser
//
//  Created by Boris Yurkevich on 06/02/2023.
//

import SwiftUI

@main
struct FileBrowserApp: App {

    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
        }
    }
}
