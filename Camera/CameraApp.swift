//
//  CameraApp.swift
//  Camera
//
//  Created by Yi Chun Chiu on 2025/1/7.
//

import SwiftUI
import SwiftData

@main
struct CameraApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Video.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
