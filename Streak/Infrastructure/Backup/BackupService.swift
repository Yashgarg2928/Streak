// Infrastructure/Backup/BackupService.swift
// Full-app backup and restore.
//
// A backup is a binary property list holding a consistent snapshot of the SwiftData
// SQLite store (taken with `VACUUM INTO`, so it's safe while the app is running) plus
// the app's settings. Restoring stages the file; the swap happens on the next launch,
// before the store is opened.

import Foundation
import SQLite3

enum BackupError: LocalizedError {
    case storeNotFound
    case snapshotFailed(String)
    case invalidFile
    case newerFormat

    var errorDescription: String? {
        switch self {
        case .storeNotFound:            return "No data found to back up yet."
        case .snapshotFailed(let why):  return "Couldn't snapshot the database: \(why)"
        case .invalidFile:              return "This file isn't a Streak backup."
        case .newerFormat:              return "This backup was made by a newer version of Streak."
        }
    }
}

struct BackupSummary {
    let createdAt: Date
    let storeSize: Int
}

enum BackupService {
    static let formatVersion = 1

    /// Keys that are rebuilt automatically and shouldn't travel with a backup.
    private static let excludedKeys: Set<String> = [
        WidgetDataStore.key,
        WidgetTaskToggleQueue.key,
        "lastActiveDateString",
    ]

    /// Staged restores and the pre-restore safety copy live next to the store
    /// (SwiftData puts it in the App Group container, not the app's own sandbox).
    private static func pendingRestoreURL(storeURL: URL) -> URL {
        storeURL.deletingLastPathComponent().appending(path: "PendingRestore.plist")
    }

    static func safetyCopyDirectory(storeURL: URL) -> URL {
        storeURL.deletingLastPathComponent().appending(path: "PreRestore")
    }

    // MARK: Export

    static func makeBackup(storeURL: URL, appGroupID: String) throws -> Data {
        let snapshotURL = FileManager.default.temporaryDirectory
            .appending(path: "streak-snapshot-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: snapshotURL) }

        try snapshotStore(at: storeURL, to: snapshotURL)

        let payload: [String: Any] = [
            "app": "Streak",
            "formatVersion": formatVersion,
            "createdAt": Date(),
            "store": try Data(contentsOf: snapshotURL),
            "appGroupDefaults": persistedDefaults(domain: appGroupID),
            "standardDefaults": Bundle.main.bundleIdentifier.map { persistedDefaults(domain: $0) } ?? [:],
        ]
        return try PropertyListSerialization.data(fromPropertyList: payload, format: .binary, options: 0)
    }

    static func suggestedFilename(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return "Streak-Backup-\(formatter.string(from: date))"
    }

    // MARK: Restore

    /// Validates a backup file and stages it to be applied on the next launch.
    @discardableResult
    static func stageRestore(from data: Data, storeURL: URL) throws -> BackupSummary {
        let payload = try decode(data)
        let directory = storeURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: pendingRestoreURL(storeURL: storeURL), options: .atomic)
        return BackupSummary(createdAt: payload.createdAt, storeSize: payload.store.count)
    }

    /// Reads a backup's metadata without staging it.
    static func inspect(_ data: Data) throws -> BackupSummary {
        let payload = try decode(data)
        return BackupSummary(createdAt: payload.createdAt, storeSize: payload.store.count)
    }

    /// Called at launch before the ModelContainer exists. The previous store is kept in
    /// a `PreRestore/` folder next to the store in case the restore needs undoing.
    static func applyPendingRestoreIfNeeded(storeURL: URL, appGroupID: String) {
        let fm = FileManager.default
        let pendingURL = pendingRestoreURL(storeURL: storeURL)
        guard fm.fileExists(atPath: pendingURL.path) else { return }
        defer { try? fm.removeItem(at: pendingURL) }

        guard let data = try? Data(contentsOf: pendingURL),
              let payload = try? decode(data) else { return }

        let safetyDir = safetyCopyDirectory(storeURL: storeURL)
        try? fm.removeItem(at: safetyDir)
        try? fm.createDirectory(at: safetyDir, withIntermediateDirectories: true)

        for suffix in ["", "-wal", "-shm"] {
            let file = URL(fileURLWithPath: storeURL.path + suffix)
            guard fm.fileExists(atPath: file.path) else { continue }
            try? fm.moveItem(at: file, to: safetyDir.appending(path: file.lastPathComponent))
        }

        do {
            try fm.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try payload.store.write(to: storeURL, options: .atomic)
        } catch {
            // Put the original store back rather than starting empty.
            for suffix in ["", "-wal", "-shm"] {
                let name = storeURL.lastPathComponent + suffix
                try? fm.moveItem(at: safetyDir.appending(path: name), to: storeURL.deletingLastPathComponent().appending(path: name))
            }
            return
        }

        restoreDefaults(payload.appGroupDefaults, domain: appGroupID)
        if let bundleID = Bundle.main.bundleIdentifier {
            restoreDefaults(payload.standardDefaults, domain: bundleID)
        }
    }

    // MARK: Internals

    private struct Payload {
        let createdAt: Date
        let store: Data
        let appGroupDefaults: [String: Any]
        let standardDefaults: [String: Any]
    }

    private static func decode(_ data: Data) throws -> Payload {
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              plist["app"] as? String == "Streak",
              let version = plist["formatVersion"] as? Int,
              let store = plist["store"] as? Data,
              store.starts(with: Array("SQLite format 3".utf8)) else {
            throw BackupError.invalidFile
        }
        guard version <= formatVersion else { throw BackupError.newerFormat }
        return Payload(
            createdAt: plist["createdAt"] as? Date ?? Date(),
            store: store,
            appGroupDefaults: plist["appGroupDefaults"] as? [String: Any] ?? [:],
            standardDefaults: plist["standardDefaults"] as? [String: Any] ?? [:]
        )
    }

    private static func snapshotStore(at storeURL: URL, to destination: URL) throws {
        guard FileManager.default.fileExists(atPath: storeURL.path) else { throw BackupError.storeNotFound }

        var db: OpaquePointer?
        guard sqlite3_open_v2(storeURL.path, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "open failed"
            sqlite3_close(db)
            throw BackupError.snapshotFailed(message)
        }
        defer { sqlite3_close(db) }

        let escapedPath = destination.path.replacingOccurrences(of: "'", with: "''")
        var errorPointer: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, "VACUUM INTO '\(escapedPath)'", nil, nil, &errorPointer) == SQLITE_OK else {
            let message = errorPointer.map { String(cString: $0) } ?? "unknown error"
            sqlite3_free(errorPointer)
            throw BackupError.snapshotFailed(message)
        }
    }

    private static func defaults(for domain: String) -> UserDefaults? {
        domain == Bundle.main.bundleIdentifier ? .standard : UserDefaults(suiteName: domain)
    }

    private static func persistedDefaults(domain: String) -> [String: Any] {
        let values = defaults(for: domain)?.persistentDomain(forName: domain) ?? [:]
        return values.filter { !excludedKeys.contains($0.key) }
    }

    private static func restoreDefaults(_ values: [String: Any], domain: String) {
        guard let defaults = defaults(for: domain) else { return }
        let current = defaults.persistentDomain(forName: domain) ?? [:]
        for key in current.keys where !excludedKeys.contains(key) {
            defaults.removeObject(forKey: key)
        }
        for (key, value) in values where !excludedKeys.contains(key) {
            defaults.set(value, forKey: key)
        }
        defaults.removeObject(forKey: "lastActiveDateString")
    }
}
