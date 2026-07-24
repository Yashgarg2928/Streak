// Application/UseCases/Tasks/CompleteTaskUseCase.swift

import Foundation

struct CompleteTaskUseCase {
    let taskRepository: any TaskRepository
    let resolveDayStatus: ResolveDayStatusUseCase
    let settingsRepository: any SettingsRepository
    let playerProfileRepository: (any PlayerProfileRepository)?
    let xpTransactionRepository: (any XPTransactionRepository)?
    let badgeRepository: (any BadgeRepository)?
    let goalRepository: (any GoalRepository)?
    let habitRoutineRepository: (any HabitRoutineRepository)?
    let dayEntryRepository: (any DayEntryRepository)?

    init(
        taskRepository: any TaskRepository,
        resolveDayStatus: ResolveDayStatusUseCase,
        settingsRepository: any SettingsRepository,
        playerProfileRepository: (any PlayerProfileRepository)? = nil,
        xpTransactionRepository: (any XPTransactionRepository)? = nil,
        badgeRepository: (any BadgeRepository)? = nil,
        goalRepository: (any GoalRepository)? = nil,
        habitRoutineRepository: (any HabitRoutineRepository)? = nil,
        dayEntryRepository: (any DayEntryRepository)? = nil
    ) {
        self.taskRepository = taskRepository
        self.resolveDayStatus = resolveDayStatus
        self.settingsRepository = settingsRepository
        self.playerProfileRepository = playerProfileRepository
        self.xpTransactionRepository = xpTransactionRepository
        self.badgeRepository = badgeRepository
        self.goalRepository = goalRepository
        self.habitRoutineRepository = habitRoutineRepository
        self.dayEntryRepository = dayEntryRepository
    }

    func execute(taskId: UUID, completed: Bool) throws {
        guard var task = try taskRepository.fetch(id: taskId) else {
            throw StreakError.taskNotFound
        }
        // Cannot complete a task that isn't for today or earlier
        let today = ActiveDayResolver.resolveActiveDate(for: Date(), settings: settingsRepository)
        guard task.targetDate <= today else { return }
        let isNewCompletion = !task.isCompleted && completed
        
        task.isCompleted = completed
        task.completedAt = completed ? Date() : nil
        try taskRepository.save(task)

        try resolveDayStatus.execute(date: task.targetDate, categoryId: task.categoryId)
        try resolveDayStatus.execute(date: task.targetDate, categoryId: nil)

        // Award XP on new task completion if repositories are wired
        if isNewCompletion,
           let pRepo = playerProfileRepository,
           let xRepo = xpTransactionRepository,
           let bRepo = badgeRepository,
           let gRepo = goalRepository,
           let hRepo = habitRoutineRepository,
           let dRepo = dayEntryRepository {
            
            let awardUseCase = AwardXPUseCase(
                playerProfileRepository: pRepo,
                xpTransactionRepository: xRepo,
                badgeRepository: bRepo,
                dayEntryRepository: dRepo,
                taskRepository: taskRepository,
                goalRepository: gRepo,
                habitRoutineRepository: hRepo
            )
            
            let xpAmount: Int
            let reason: XPTransactionReason
            if task.routineId != nil {
                xpAmount = 15
                reason = .habitCompleted
            } else {
                switch task.timeframe {
                case .weekly:
                    xpAmount = 30
                    reason = .weeklyTaskCompleted
                case .monthly:
                    xpAmount = 80
                    reason = .monthlyTaskCompleted
                case .backlog:
                    xpAmount = 20
                    reason = .backlogTaskCompleted
                case .daily:
                    xpAmount = 10
                    reason = .taskCompleted
                }
            }
            
            _ = try awardUseCase.execute(amount: xpAmount, reason: reason, note: task.title)
            
            // Check if day became overall green
            let masterEntries = try dRepo.fetchAll(categoryId: nil)
            if let todayEntry = masterEntries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: task.targetDate) }),
               todayEntry.status == .green {
                // Streak multiplier check
                let streak = (try? CalculateStreakUseCase(dayEntryRepository: dRepo).execute(categoryId: nil)) ?? 1
                let multiplier: Double
                switch streak {
                case 7...13: multiplier = 1.2
                case 14...29: multiplier = 1.5
                case 30...59: multiplier = 2.0
                case 60...99: multiplier = 2.5
                case 100...: multiplier = 3.0
                default: multiplier = 1.0
                }
                let bonus = Int(50.0 * multiplier)
                _ = try awardUseCase.execute(amount: bonus, reason: .overallGreenDay, note: "Overall Green Day (\(streak)d streak multiplier)")
            }
        }
    }
}
