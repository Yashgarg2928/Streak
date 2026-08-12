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

    public func execute(jsonString: String) throws -> WorkoutPlan {
        let cleanedJson = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
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
