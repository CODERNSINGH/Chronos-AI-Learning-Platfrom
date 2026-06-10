//
//  chronosApp.swift
//  chronos
//
//  Created by Narendra Singh on 04/06/26.
//

import SwiftUI
import SwiftData

@main
struct chronosApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            TopicNode.self,
            QuizAttempt.self,
            Achievement.self
        ])
        return Self.makeContainer(schema: schema)
    }()

    /// Build a ModelContainer backed by the on-disk store. If a previous
    /// launch wrote data with an older schema, the open will fail with a
    /// migration error. In that case we wipe the store and recreate it
    /// (acceptable during development; production would use a versioned
    /// schema instead). We never silently fall back to an in-memory store,
    /// because that would cause the user's data to disappear on every relaunch.
    private static func makeContainer(schema: Schema) -> ModelContainer {
        let storeURL = defaultStoreURL()
        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("[chronos] Failed to open store at \(storeURL.path): \(error). Wiping and recreating.")
            wipeStore(at: storeURL)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer after wipe: \(error)")
            }
        }
    }

    private static func defaultStoreURL() -> URL {
        let fm = FileManager.default
        if let appSupport = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            return appSupport.appendingPathComponent("default.store")
        }
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("default.store")
    }

    /// SwiftData / Core Data writes three files: the main store, the shared
    /// memory file (-shm), and the write-ahead log (-wal). All three must be
    /// removed to fully reset the persistent store.
    private static func wipeStore(at url: URL) {
        let fm = FileManager.default
        let dir = url.deletingLastPathComponent()
        let base = url.lastPathComponent
        for suffix in ["", "-shm", "-wal"] {
            let path = dir.appendingPathComponent(base + suffix)
            try? fm.removeItem(at: path)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

/// Routes the app to either the normal ContentView or the screenshot-tour view
/// based on a launch argument. The screenshot tour lets us launch directly into
/// a specific screen with rich mock data so we can take consistent screenshots.
struct RootView: View {
    private var tourScreen: String? {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-chronos-screen"),
           idx + 1 < args.count {
            return args[idx + 1]
        }
        return nil
    }

    var body: some View {
        if let screen = tourScreen {
            ScreenshotTourView(screen: screen)
        } else {
            ContentView()
        }
    }
}
