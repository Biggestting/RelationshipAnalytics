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

    private let staleDuration: TimeInterval = 4 * 3600 // 4 hours

    private init() {
        self.lastSyncDate = UserDefaults.standard.object(forKey: "lastAutoSync") as? Date
        self.autoSyncEnabled = UserDefaults.standard.bool(forKey: "autoSyncEnabled")
    }

    // MARK: - Background App Refresh

    /// Call from app launch to register the background task
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
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // earliest: 1 hour from now
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Background refresh scheduling can fail silently
        }
    }

    private func handleBackgroundRefresh(_ task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleBackgroundRefresh()

        let syncTask = Task {
            await performSync(source: "background")
        }

        task.expirationHandler = {
            syncTask.cancel()
        }

        Task {
            await syncTask.value
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Foreground Sync

    /// Call when app enters foreground — syncs if data is stale
    func syncIfNeeded() {
        guard autoSyncEnabled else { return }

        let isStale: Bool
        if let lastSync = lastSyncDate {
            isStale = Date().timeIntervalSince(lastSync) > staleDuration
        } else {
            isStale = true
        }

        if isStale {
            Task { await performSync(source: "foreground") }
        }
    }

    // MARK: - Core Sync

    @MainActor
    func performSync(source: String) async {
        guard !isSyncing else { return }
        isSyncing = true
        syncStatus = "SYNCING (\(source.uppercased()))..."

        // Re-run any Shortcuts-imported contacts to check for new messages
        // The App Intent will be triggered by the Shortcuts Automation
        // Here we just mark the sync time and update status

        // Check if we have any Shortcuts imports to refresh
        let imports = LiveDataStore.shared.getAllShortcutsImports()
        if !imports.isEmpty {
            syncStatus = "PROCESSING \(imports.count) CONTACTS..."
            // The actual re-import happens via the Shortcuts Automation
            // We just record that we're ready for fresh data
        }

        // Update tracked call data
        let calls = LiveDataStore.shared.getAllCalls()
        syncStatus = "\(calls.count) CALLS TRACKED"

        // Mark sync complete
        lastSyncDate = Date()
        isSyncing = false
        syncStatus = "LAST SYNC: \(formattedSyncDate)"
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
