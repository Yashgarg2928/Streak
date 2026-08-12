// Domain/Entities/MealLog.swift

import Foundation

public enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    public var id: String { rawValue }

    public var emoji: String {
        switch self {
        case .breakfast: return "🌅"
        case .lunch:     return "☀️"
        case .dinner:    return "🌙"
        case .snack:     return "🍎"
        }
    }
}

public struct MealLog: Codable, Equatable, Identifiable {
    public var id: UUID
    public var date: Date
    public var mealType: MealType
    public var title: String
    public var details: String
    public var calories: Int
    public var proteinGrams: Double
    public var carbGrams: Double
    public var fatGrams: Double
    public var photoData: Data?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        mealType: MealType = .breakfast,
        title: String,
        details: String = "",
        calories: Int = 0,
        proteinGrams: Double = 0.0,
        carbGrams: Double = 0.0,
        fatGrams: Double = 0.0,
        photoData: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.title = title
        self.details = details
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbGrams = carbGrams
        self.fatGrams = fatGrams
        self.photoData = photoData
    }
}

public struct MacroGoals: Codable, Equatable {
    public var targetCalories: Int
    public var targetProteinGrams: Double
    public var targetCarbGrams: Double
    public var targetFatGrams: Double

    public init(
        targetCalories: Int = 2200,
        targetProteinGrams: Double = 150.0,
        targetCarbGrams: Double = 220.0,
        targetFatGrams: Double = 65.0
    ) {
        self.targetCalories = targetCalories
        self.targetProteinGrams = targetProteinGrams
        self.targetCarbGrams = targetCarbGrams
        self.targetFatGrams = targetFatGrams
    }
}
