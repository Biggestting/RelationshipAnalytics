import Foundation
import BackgroundTasks
#if canImport(UIKit)
import UIKit
#endif

/// Manages automatic data syncing via:
/// 1. Background App Refresh — iOS wakes the app periodically to re-import
/// 2. Foreground re-sync — when the app comes to foreground, check if stale
/// 3. Shortcuts Automation companion — guide user to set up auto-trigger
final class AutoSyncManager: ObservableObject {
    static let shared = AutoSyncManager()
    static let backgroundTaskID = "com.relationshipanalytics.refresh"

    /// URL scheme that triggers the import Shortcut
    /// The user's Shortcut should be named "Export Messages to RA"
    private let shortcutRunURL = "shortcuts://run-shortcut?name=Export%20Messages%20to%20RA"

    @Published var lastSyncDate: Date? {
        didSet {
            if let date = lastSyncDate {
                UserDefaults.standard.set(date, forKey: "lastAutoSync")
            }
        }
    }
    @Published var isSyncing = false
    @Published var syncStatus: String = ""
    @Published var autoSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoSyncEnabled, forKey: "autoSyncEnabled")
            if autoSyncEnabled {
                scheduleBackgroundRefresh()
            }
        }
    }
    @Published var shortcutInstalled: Bool {
        didSet {
            UserDefaults.standard.set(shortcutInstalled, forKey: "shortcutInstalled")
        }
    }

    private let staleDuration: TimeInterval = 4 * 3600

    private init() {
        self.lastSyncDate = UserDefaults.standard.object(forKey: "lastAutoSync") as? Date
        self.autoSyncEnabled = UserDefaults.standard.bool(forKey: "autoSyncEnabled")
        self.shortcutInstalled = UserDefaults.standard.bool(forKey: "shortcutInstalled")
    }

    // MARK: - Background App Refresh

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskID,
            using: nil
        ) { [weak self] task in
            self?.handleBackgroundRefresh(task as! BGAppRefreshTask)
        }

        if autoSyncEnabled {
            scheduleBackgroundRefresh()
        }
    }

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Background refresh scheduling can fail silently
        }
    }

    private func handleBackgroundRefresh(_ task: BGAppRefreshTask) {
        scheduleBackgroundRefresh()

        let syncTask = Task {
            await performSync(source: "background")
        }

        task.expirationHandler = { syncTask.cancel() }

        Task {
            await syncTask.value
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Foreground Sync

    func syncIfNeeded() {
        guard autoSyncEnabled else { return }

        let isCurrentlyStale: Bool
        if let lastSync = lastSyncDate {
            isCurrentlyStale = Date().timeIntervalSince(lastSync) > staleDuration
        } else {
            isCurrentlyStale = true
        }

        if isCurrentlyStale {
            Task { await performSync(source: "foreground") }
        }
    }

    // MARK: - Core Sync

    @MainActor
    func performSync(source: String) async {
        guard !isSyncing else { return }
        isSyncing = true
        syncStatus = "SYNCING (\(source.uppercased()))..."

        #if canImport(UIKit)
        if shortcutInstalled, source == "manual" {
            // Launch the Shortcuts app to run our import Shortcut
            syncStatus = "LAUNCHING SHORTCUT..."
            if let url = URL(string: shortcutRunURL) {
                await UIApplication.shared.open(url)
            }
            // The Shortcut will call back via our App Intent or URL scheme
            // when it finishes, triggering data reload
            try? await Task.sleep(nanoseconds: 2_000_000_000) // wait 2s for shortcut to start
            syncStatus = "SHORTCUT RUNNING — SWITCH BACK WHEN DONE"
            isSyncing = false
            return
        }
        #endif

        // For background/foreground auto-sync, just update tracked data
        let imports = LiveDataStore.shared.getAllShortcutsImports()
        let calls = LiveDataStore.shared.getAllCalls()
        let messageCounts = LiveDataStore.shared.getAllMessageCounts()

        if !imports.isEmpty || !calls.isEmpty || !messageCounts.isEmpty {
            syncStatus = "\(imports.count) CONTACTS · \(calls.count) CALLS"
        } else {
            syncStatus = "NO DATA YET — IMPORT FIRST"
        }

        lastSyncDate = Date()
        isSyncing = false
        syncStatus = imports.isEmpty && calls.isEmpty
            ? "NO DATA YET — SET UP SHORTCUTS IMPORT"
            : "LAST SYNC: \(formattedSyncDate)"
    }

    // MARK: - Helpers

    var formattedSyncDate: String {
        guard let date = lastSyncDate else { return "NEVER" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date()).uppercased()
    }

    var isStale: Bool {
        guard let lastSync = lastSyncDate else { return true }
        return Date().timeIntervalSince(lastSync) > staleDuration
    }
}
