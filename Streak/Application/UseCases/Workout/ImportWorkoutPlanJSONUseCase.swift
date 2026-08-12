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

    public static func stripMarkdownCodeBlocks(_ input: String) -> String {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
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

    public func execute(jsonString: String) throws -> WorkoutPlan {
        let cleanedJson = Self.extractJSONSubstring(jsonString)
        guard let data = cleanedJson.data(using: .utf8) else {
            throw WorkoutPlanImportError.invalidJSON("Could not read text as UTF-8.")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let plan: WorkoutPlan
        do {
            plan = try decoder.decode(WorkoutPlan.self, from: data)
        } catch {
            // Fallback decode without snake_case strategy
            let fallbackDecoder = JSONDecoder()
            do {
                plan = try fallbackDecoder.decode(WorkoutPlan.self, from: data)
            } catch let fallbackError {
                throw WorkoutPlanImportError.invalidJSON(fallbackError.localizedDescription)
            }
        }

        guard !plan.days.isEmpty else {
            throw WorkoutPlanImportError.emptyPlan
        }

        try workoutRepository.savePlan(plan)
        return plan
    }
}
