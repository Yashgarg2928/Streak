// Domain/Entities/WorkoutPlan.swift

import Foundation

public func cleanURLString(_ str: String?) -> String? {
    guard let str = str?.trimmingCharacters(in: .whitespacesAndNewlines), !str.isEmpty else { return nil }

    // Check if markdown link format [label](url)
    if let match = str.range(of: #"\((https?://[^\s\)]+)\)"#, options: .regularExpression) {
        let matched = String(str[match])
        let urlOnly = matched.dropFirst().dropLast() // drop '(' and ')'
        return String(urlOnly)
    }

    // Otherwise extract direct URL without brackets
    if let match = str.range(of: #"https?://[^\s\]\)]+"#, options: .regularExpression) {
        return String(str[match])
    }

    return str
}

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

    enum CodingKeys: String, CodingKey {
        case id, setNumber, weight, reps, isCompleted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.setNumber = (try? container.decode(Int.self, forKey: .setNumber)) ?? 1
        self.weight = (try? container.decode(Double.self, forKey: .weight)) ?? 0.0
        self.reps = (try? container.decode(Int.self, forKey: .reps)) ?? 10
        self.isCompleted = (try? container.decode(Bool.self, forKey: .isCompleted)) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(setNumber, forKey: .setNumber)
        try container.encode(weight, forKey: .weight)
        try container.encode(reps, forKey: .reps)
        try container.encode(isCompleted, forKey: .isCompleted)
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
        self.youtubeUrl = cleanURLString(youtubeUrl)
        self.notes = notes
    }

    enum CodingKeys: String, CodingKey {
        case id, exerciseName, category, sets, stepCount, youtubeUrl, notes, name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        let nameField = (try? container.decode(String.self, forKey: .exerciseName)) ?? (try? container.decode(String.self, forKey: .name)) ?? "Exercise"
        self.exerciseName = nameField
        self.category = (try? container.decode(String.self, forKey: .category)) ?? "General"
        self.sets = (try? container.decode([WorkoutSetLog].self, forKey: .sets)) ?? []
        self.stepCount = try? container.decode(Int.self, forKey: .stepCount)
        let rawUrl = try? container.decode(String.self, forKey: .youtubeUrl)
        self.youtubeUrl = cleanURLString(rawUrl)
        self.notes = try? container.decode(String.self, forKey: .notes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(exerciseName, forKey: .exerciseName)
        try container.encode(category, forKey: .category)
        try container.encode(sets, forKey: .sets)
        try container.encodeIfPresent(stepCount, forKey: .stepCount)
        try container.encodeIfPresent(youtubeUrl, forKey: .youtubeUrl)
        try container.encodeIfPresent(notes, forKey: .notes)
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
        self.youtubeUrl = cleanURLString(youtubeUrl)
        self.notes = notes
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, targetSets, targetRepsOrDuration, youtubeUrl, notes, exerciseName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        let exName = (try? container.decode(String.self, forKey: .name)) ?? (try? container.decode(String.self, forKey: .exerciseName)) ?? "Exercise"
        self.name = exName
        self.category = (try? container.decode(String.self, forKey: .category)) ?? "General"
        self.targetSets = (try? container.decode(Int.self, forKey: .targetSets)) ?? 3
        
        if let repsStr = try? container.decode(String.self, forKey: .targetRepsOrDuration) {
            self.targetRepsOrDuration = repsStr
        } else if let repsInt = try? container.decode(Int.self, forKey: .targetRepsOrDuration) {
            self.targetRepsOrDuration = "\(repsInt) reps"
        } else {
            self.targetRepsOrDuration = "8-12 reps"
        }

        let rawUrl = try? container.decode(String.self, forKey: .youtubeUrl)
        self.youtubeUrl = cleanURLString(rawUrl)
        self.notes = try? container.decode(String.self, forKey: .notes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(targetSets, forKey: .targetSets)
        try container.encode(targetRepsOrDuration, forKey: .targetRepsOrDuration)
        try container.encodeIfPresent(youtubeUrl, forKey: .youtubeUrl)
        try container.encodeIfPresent(notes, forKey: .notes)
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

    enum CodingKeys: String, CodingKey {
        case id, dayName, dayOfWeek, title, exercises
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        let name = (try? container.decode(String.self, forKey: .dayName)) ?? "Monday"
        self.dayName = name

        if let num = try? container.decode(Int.self, forKey: .dayOfWeek) {
            self.dayOfWeek = num
        } else {
            self.dayOfWeek = WorkoutDayPlan.inferDayOfWeek(from: name)
        }

        self.title = (try? container.decode(String.self, forKey: .title)) ?? name
        self.exercises = (try? container.decode([WorkoutExercisePlan].self, forKey: .exercises)) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(dayName, forKey: .dayName)
        try container.encode(dayOfWeek, forKey: .dayOfWeek)
        try container.encode(title, forKey: .title)
        try container.encode(exercises, forKey: .exercises)
    }

    public static func inferDayOfWeek(from dayName: String) -> Int {
        let lower = dayName.lowercased()
        if lower.contains("sun") { return 1 }
        if lower.contains("mon") { return 2 }
        if lower.contains("tue") { return 3 }
        if lower.contains("wed") { return 4 }
        if lower.contains("thu") { return 5 }
        if lower.contains("fri") { return 6 }
        if lower.contains("sat") { return 7 }
        return 2 // default Monday
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

    enum CodingKeys: String, CodingKey {
        case id, title, createdAt, days
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.title = (try? container.decode(String.self, forKey: .title)) ?? "Weekly Workout Plan"
        self.createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        self.days = (try? container.decode([WorkoutDayPlan].self, forKey: .days)) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(days, forKey: .days)
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

    enum CodingKeys: String, CodingKey {
        case id, date, dayName, exercises, notes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.date = (try? container.decode(Date.self, forKey: .date)) ?? Date()
        self.dayName = (try? container.decode(String.self, forKey: .dayName)) ?? ""
        self.exercises = (try? container.decode([ExerciseLog].self, forKey: .exercises)) ?? []
        self.notes = try? container.decode(String.self, forKey: .notes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(dayName, forKey: .dayName)
        try container.encode(exercises, forKey: .exercises)
        try container.encodeIfPresent(notes, forKey: .notes)
    }

    public var totalDailyVolume: Double {
        exercises.reduce(0.0) { $0 + $1.totalVolume }
    }

    public var totalStepCount: Int {
        exercises.compactMap { $0.stepCount }.reduce(0, +)
    }
}
