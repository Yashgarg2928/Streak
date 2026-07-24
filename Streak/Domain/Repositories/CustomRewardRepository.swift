// Domain/Repositories/CustomRewardRepository.swift

import Foundation

public protocol CustomRewardRepository {
    func fetchAll() throws -> [CustomReward]
    func fetchAll(categoryId: UUID?) throws -> [CustomReward]
    func fetch(id: UUID) throws -> CustomReward?
    func save(_ reward: CustomReward) throws
    func delete(id: UUID) throws
}
