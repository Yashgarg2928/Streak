// Application/UseCases/Workout/ImportWorkoutPlanJSONUseCase.swift

import Foundation

public enum WorkoutPlanImportError: LocalizedError {
    case invalidJSON(String)
    case emptyPlan

    public var errorDescription: String? {
        switch self {
        case .invalidJSON(let details):
            return "Invalid Workout Plan JSON: \(details)"
        case .emptyPlan:
            return "The workout plan contains no days or exercises."
        }
    }
}

public struct ImportWorkoutPlanJSONUseCase {
    let workoutRepository: any WorkoutRepository

    public init(workoutRepository: any WorkoutRepository) {
        self.workoutRepository = workoutRepository
    }

    public static func sanitizeJSONString(_ input: String) -> String {
        var sanitized = input
        sanitized = sanitized.replacingOccurrences(of: "“", with: "\"")
        sanitized = sanitized.replacingOccurrences(of: "”", with: "\"")
        sanitized = sanitized.replacingOccurrences(of: "„", with: "\"")
        sanitized = sanitized.replacingOccurrences(of: "«", with: "\"")
        sanitized = sanitized.replacingOccurrences(of: "»", with: "\"")
        sanitized = sanitized.replacingOccurrences(of: "‘", with: "'")
        sanitized = sanitized.replacingOccurrences(of: "’", with: "'")
        sanitized = sanitized.replacingOccurrences(of: "\u{00A0}", with: " ")
        sanitized = sanitized.replacingOccurrences(of: "\u{200B}", with: "")
        sanitized = sanitized.replacingOccurrences(of: "\u{FEFF}", with: "")
        return sanitized
    }

    public static func stripMarkdownCodeBlocks(_ input: String) -> String {
        let sanitized = sanitizeJSONString(input)
        var text = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            if let firstNewline = text.firstIndex(of: "\n") {
                text = String(text[text.index(after: firstNewline)...])
            } else {
                text = text.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "")
            }
        }
        if text.hasSuffix("```") {
            if let lastBacktickPos = text.range(of: "```", options: .backwards) {
                text = String(text[..<lastBacktickPos.lowerBound])
            }
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func extractJSONSubstring(_ input: String) -> String {
        let stripped = stripMarkdownCodeBlocks(input)

        let firstBrace = stripped.firstIndex(of: "{")
        let firstBracket = stripped.firstIndex(of: "[")

        let startIndex: String.Index
        if let b = firstBrace, let k = firstBracket {
            startIndex = min(b, k)
        } else if let b = firstBrace {
            startIndex = b
        } else if let k = firstBracket {
            startIndex = k
        } else {
            return stripped
        }

        let lastBrace = stripped.lastIndex(of: "}")
        let lastBracket = stripped.lastIndex(of: "]")

        let endIndex: String.Index
        if let b = lastBrace, let k = lastBracket {
            endIndex = max(b, k)
        } else if let b = lastBrace {
            endIndex = b
        } else if let k = lastBracket {
            endIndex = k
        } else {
            return String(stripped[startIndex...])
        }

        return String(stripped[startIndex...endIndex])
    }

    public static func parseFromDictionary(_ dict: [String: Any]) -> WorkoutPlan? {
        let title = (dict["title"] as? String) ?? "My Weekly Workout Plan"
        let daysRaw = (dict["days"] as? [[String: Any]]) ?? []
        guard !daysRaw.isEmpty else { return nil }

        let parsedDays: [WorkoutDayPlan] = daysRaw.compactMap { dayDict in
            let dayName = (dayDict["dayName"] as? String) ?? (dayDict["day_name"] as? String) ?? "Monday"
            let dayOfWeek: Int
            if let dow = dayDict["dayOfWeek"] as? Int ?? dayDict["day_of_week"] as? Int {
                dayOfWeek = dow
            } else if let dowStr = dayDict["dayOfWeek"] as? String, let dowInt = Int(dowStr) {
                dayOfWeek = dowInt
            } else {
                dayOfWeek = WorkoutDayPlan.inferDayOfWeek(from: dayName)
            }
            let dayTitle = (dayDict["title"] as? String) ?? dayName

            let exercisesRaw = (dayDict["exercises"] as? [[String: Any]]) ?? []
            let parsedExercises: [WorkoutExercisePlan] = exercisesRaw.compactMap { exDict in
                let exName = (exDict["name"] as? String) ?? (exDict["exerciseName"] as? String) ?? (exDict["exercise_name"] as? String) ?? "Exercise"
                let category = (exDict["category"] as? String) ?? "General"
                let targetSets = (exDict["targetSets"] as? Int) ?? (exDict["target_sets"] as? Int) ?? 3
                let repsStr: String
                if let reps = exDict["targetRepsOrDuration"] as? String ?? exDict["target_reps_or_duration"] as? String {
                    repsStr = reps
                } else {
                    repsStr = "8-12 reps"
                }
                let rawUrl = (exDict["youtubeUrl"] as? String) ?? (exDict["youtube_url"] as? String)
                let notes = (exDict["notes"] as? String)

                return WorkoutExercisePlan(
                    name: exName,
                    category: category,
                    targetSets: targetSets,
                    targetRepsOrDuration: repsStr,
                    youtubeUrl: cleanURLString(rawUrl),
                    notes: notes
                )
            }

            return WorkoutDayPlan(
                dayName: dayName,
                dayOfWeek: dayOfWeek,
                title: dayTitle,
                exercises: parsedExercises
            )
        }

        guard !parsedDays.isEmpty else { return nil }
        return WorkoutPlan(title: title, days: parsedDays)
    }

    public func execute(jsonString: String) throws -> WorkoutPlan {
        let cleanedJson = Self.extractJSONSubstring(jsonString)
        guard let data = cleanedJson.data(using: .utf8) else {
            throw WorkoutPlanImportError.invalidJSON("Could not read text as UTF-8.")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        var parsedPlan: WorkoutPlan? = nil
        do {
            parsedPlan = try decoder.decode(WorkoutPlan.self, from: data)
        } catch {
            let fallbackDecoder = JSONDecoder()
            if let plan = try? fallbackDecoder.decode(WorkoutPlan.self, from: data) {
                parsedPlan = plan
            } else if let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                      let dictPlan = Self.parseFromDictionary(dict) {
                parsedPlan = dictPlan
            } else {
                throw WorkoutPlanImportError.invalidJSON(error.localizedDescription)
            }
        }

        guard let plan = parsedPlan, !plan.days.isEmpty else {
            throw WorkoutPlanImportError.emptyPlan
        }

        try workoutRepository.savePlan(plan)
        return plan
    }
}
