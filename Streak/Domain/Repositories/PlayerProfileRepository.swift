// Domain/Repositories/PlayerProfileRepository.swift

import Foundation

public protocol PlayerProfileRepository {
    func fetchProfile() throws -> PlayerProfile
    func saveProfile(_ profile: PlayerProfile) throws
}
