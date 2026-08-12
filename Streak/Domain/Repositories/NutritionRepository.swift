// Domain/Repositories/NutritionRepository.swift

import Foundation

public protocol NutritionRepository {
    func fetchMealLogs(for date: Date) throws -> [MealLog]
    func fetchMealLogs(startDate: Date, endDate: Date) throws -> [MealLog]
    func saveMealLog(_ meal: MealLog) throws
    func deleteMealLog(id: UUID) throws
    
    func fetchMacroGoals() throws -> MacroGoals
    func saveMacroGoals(_ goals: MacroGoals) throws
}
