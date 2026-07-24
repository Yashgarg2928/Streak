// Domain/Repositories/BadgeRepository.swift

import Foundation

public protocol BadgeRepository {
    func fetchAll() throws -> [Badge]
    func fetch(byKey badgeKey: String) throws -> Badge?
    func save(_ badge: Badge) throws
}
