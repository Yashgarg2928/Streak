// Domain/StreakError.swift
// All domain-level errors. Use cases throw these; ViewModels catch and display them.

import Foundation

enum StreakError: LocalizedError {
    case emptyTitle
    case invalidColor
    case categoryNotFound
    case taskNotFound
    case goalNotFound
    case invalidTargetDate
    case importVersionMismatch(Int)

    var errorDescription: String? {
        switch self {
        case .emptyTitle:           return "Title cannot be empty."
        case .invalidColor:         return "Please choose a valid color."
        case .categoryNotFound:     return "Category not found or has been archived."
        case .taskNotFound:         return "Task not found."
        case .goalNotFound:         return "Goal not found."
        case .invalidTargetDate:    return "Tasks can only be set for today or tomorrow."
        case .importVersionMismatch(let v):
            return "This backup was created with a newer version of Streak (v\(v)). Please update the app."
        }
    }
}
