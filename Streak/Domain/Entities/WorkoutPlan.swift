// Domain/Entities/WorkoutPlan.swift

import Foundation

public struct WorkoutSetLog: Codable, Equatable, Identifiable {
    public var id: UUID
    public var setNumber: Int
    public var weight: Double       // kg or lbs
    public var reps: Int
    public var isCompleted: Bool

    public init(
        id: UUID = UUID(),
        setNumber: Int,
        weight: Double = 0.0,
        reps: Int = 0,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isCompleted = isCompleted
    }
}

public struct ExerciseLog: Codable, Equatable, Identifiable {
    public var id: UUID
    public var exerciseName: String
    public var category: String           // e.g., "Chest", "Legs", "Cardio"
    public var sets: [WorkoutSetLog]
    public var stepCount: Int?           // for walking / cardio
    public var youtubeUrl: String?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        exerciseName: String,
        category: String = "General",
        sets: [WorkoutSetLog] = [],
        stepCount: Int? = nil,
        youtubeUrl: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.category = category
        self.sets = sets
        self.stepCount = stepCount
        self.youtubeUrl = youtubeUrl
        self.notes = notes
    }

    public var totalVolume: Double {
        sets.filter { $0.isCompleted }.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
    }
}

public struct WorkoutExercisePlan: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var category: String
    public var targetSets: Int
    public var targetRepsOrDuration: String
    public var youtubeUrl: String?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        name: String,
        category: String = "General",
        targetSets: Int = 3,
        targetRepsOrDuration: String = "8-12 reps",
        youtubeUrl: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.targetSets = targetSets
        self.targetRepsOrDuration = targetRepsOrDuration
        self.youtubeUrl = youtubeUrl
        self.notes = notes
    }
}

public struct WorkoutDayPlan: Codable, Equatable, Identifiable {
    public var id: UUID
    public var dayName: String           // "Monday", "Tuesday", etc.
    public var dayOfWeek: Int            // 1 = Sunday, 2 = Monday ... 7 = Saturday
    public var title: String              // e.g. "Push Day - Chest & Triceps", "Rest Day"
    public var exercises: [WorkoutExercisePlan]

    public init(
        id: UUID = UUID(),
        dayName: String,
        dayOfWeek: Int,
        title: String,
        exercises: [WorkoutExercisePlan] = []
    ) {
        self.id = id
        self.dayName = dayName
        self.dayOfWeek = dayOfWeek
        self.title = title
        self.exercises = exercises
    }
}

public struct WorkoutPlan: Codable, Equatable, Identifiable {
    public var id: UUID
    public var title: String
    public var createdAt: Date
    public var days: [WorkoutDayPlan]

    public init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        days: [WorkoutDayPlan] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.days = days
    }
}

public struct DailyWorkoutLog: Codable, Equatable, Identifiable {
    public var id: UUID
    public var date: Date
    public var dayName: String
    public var exercises: [ExerciseLog]
    public var notes: String?

    public init(
        id: UUID = UUID(),
        date: Date,
        dayName: String = "",
        exercises: [ExerciseLog] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.dayName = dayName
        self.exercises = exercises
        self.notes = notes
    }

    public var totalDailyVolume: Double {
        exercises.reduce(0.0) { $0 + $1.totalVolume }
    }

    public var totalStepCount: Int {
        exercises.compactMap { $0.stepCount }.reduce(0, +)
    }
}
