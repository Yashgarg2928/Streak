// Domain/Repositories/WorkoutRepository.swift

import Foundation

public protocol WorkoutRepository {
    func fetchActivePlan() throws -> WorkoutPlan?
    func savePlan(_ plan: WorkoutPlan) throws
    func deletePlan(id: UUID) throws
    
    func fetchDailyLog(date: Date) throws -> DailyWorkoutLog?
    func fetchLogs(startDate: Date, endDate: Date) throws -> [DailyWorkoutLog]
    func saveDailyLog(_ log: DailyWorkoutLog) throws
}
