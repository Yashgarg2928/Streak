// Infrastructure/Config/AppConfig.swift
// Centralized configuration loader for environment setup.
// Reads from .env file or ProcessInfo environment, with default fallbacks.

import Foundation

public enum AppConfig {
    public static var appGroupID: String {
        value(forKey: "APP_GROUP_ID", default: "group.com.madhvan.streak")
    }

    public static var backgroundTaskId: String {
        value(forKey: "BACKGROUND_TASK_ID", default: "com.madhvan.streak.lockoutSweep")
    }

    public static var activeDayStartHour: Int {
        Int(value(forKey: "ACTIVE_DAY_START_HOUR", default: "4")) ?? 4
    }

    public static var activeDayEndHour: Int {
        Int(value(forKey: "ACTIVE_DAY_END_HOUR", default: "23")) ?? 23
    }

    public static var planningReminderHour: Int {
        Int(value(forKey: "PLANNING_REMINDER_HOUR", default: "22")) ?? 22
    }

    public static var planningReminderMinute: Int {
        Int(value(forKey: "PLANNING_REMINDER_MINUTE", default: "0")) ?? 0
    }

    public static var defaultNotificationPersona: String {
        value(forKey: "NOTIFICATION_PERSONA", default: "savage")
    }

    public static var geminiApiKey: String {
        value(forKey: "GEMINI_API_KEY", default: "")
    }

    // MARK: - Internal .env Parser

    private static let envValues: [String: String] = {
        var dict: [String: String] = [:]

        let possiblePaths = [
            Bundle.main.path(forResource: ".env", ofType: nil),
            Bundle.main.path(forResource: "env", ofType: nil),
            Bundle.main.path(forResource: ".env", ofType: "txt")
        ].compactMap { $0 }

        for path in possiblePaths {
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                parse(content: content, into: &dict)
                return dict
            }
        }
        return dict
    }()

    private static func value(forKey key: String, default defaultValue: String) -> String {
        if let envVal = ProcessInfo.processInfo.environment[key], !envVal.isEmpty {
            return envVal
        }
        return envValues[key] ?? defaultValue
    }

    private static func parse(content: String, into dict: inout [String: String]) {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            let parts = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let val = parts[1].trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\"\'"))
                dict[key] = val
            }
        }
    }
}
