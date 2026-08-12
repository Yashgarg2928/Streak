// Application/UseCases/Nutrition/ImportMealMacroJSONUseCase.swift

import Foundation

public enum MealMacroImportError: LocalizedError {
    case invalidJSON(String)
    case emptyMeals

    public var errorDescription: String? {
        switch self {
        case .invalidJSON(let details):
            return "Invalid Meal Macro JSON: \(details)"
        case .emptyMeals:
            return "No meal data found in JSON."
        }
    }
}

public struct ImportMealMacroJSONUseCase {
    let nutritionRepository: any NutritionRepository

    public init(nutritionRepository: any NutritionRepository) {
        self.nutritionRepository = nutritionRepository
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

    public func execute(jsonString: String, for date: Date) throws -> [MealLog] {
        let cleanedJson = Self.extractJSONSubstring(jsonString)
        guard let data = cleanedJson.data(using: .utf8) else {
            throw MealMacroImportError.invalidJSON("Could not read text as UTF-8.")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        var importedMeals: [MealLog] = []

        // Try decoding array of meals first
        if let mealsArray = try? decoder.decode([MealLogInput].self, from: data) {
            importedMeals = mealsArray.map { $0.toMealLog(for: date) }
        } else if let singleMeal = try? decoder.decode(MealLogInput.self, from: data) {
            importedMeals = [singleMeal.toMealLog(for: date)]
        } else {
            // Fallback try without snake case
            let fallbackDecoder = JSONDecoder()
            if let mealsArray = try? fallbackDecoder.decode([MealLogInput].self, from: data) {
                importedMeals = mealsArray.map { $0.toMealLog(for: date) }
            } else if let singleMeal = try? fallbackDecoder.decode(MealLogInput.self, from: data) {
                importedMeals = [singleMeal.toMealLog(for: date)]
            } else {
                throw MealMacroImportError.invalidJSON("Ensure JSON matches the Meal Macro schema.")
            }
        }

        guard !importedMeals.isEmpty else {
            throw MealMacroImportError.emptyMeals
        }

        for meal in importedMeals {
            try nutritionRepository.saveMealLog(meal)
        }

        return importedMeals
    }
}

private struct MealLogInput: Codable {
    var mealType: String?
    var title: String
    var details: String?
    var calories: Int?
    var proteinGrams: Double?
    var carbGrams: Double?
    var fatGrams: Double?

    func toMealLog(for date: Date) -> MealLog {
        let parsedType = MealType(rawValue: mealType?.capitalized ?? "") ?? .breakfast
        return MealLog(
            date: date,
            mealType: parsedType,
            title: title,
            details: details ?? "",
            calories: calories ?? 0,
            proteinGrams: proteinGrams ?? 0.0,
            carbGrams: carbGrams ?? 0.0,
            fatGrams: fatGrams ?? 0.0
        )
    }
}
