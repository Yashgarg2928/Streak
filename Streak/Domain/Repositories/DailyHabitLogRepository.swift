// Domain/Repositories/DailyHabitLogRepository.swift

import Foundation

public protocol DailyHabitLogRepository {
    func fetchLogs(for date: Date) throws -> [DailyHabitLog]
    func fetchLog(habitId: UUID, date: Date) throws -> DailyHabitLog?
    func save(_ log: DailyHabitLog) throws
}
