// Application/UseCases/Reflection/SaveReflectionUseCase.swift

import Foundation

struct SaveReflectionUseCase {
    let repository: any ReflectionRepository

    func execute(_ entry: ReflectionEntry) throws {
        var updated = entry
        updated.updatedAt = Date()
        try repository.save(updated)
    }
}
