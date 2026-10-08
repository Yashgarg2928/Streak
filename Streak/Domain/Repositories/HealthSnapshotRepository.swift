// Domain/Repositories/HealthSnapshotRepository.swift
// Protocol only — no concrete implementation here

import Foundation

protocol HealthSnapshotRepository {
    func fetch(date: Date) throws -> HealthSnapshot?
    func fetchRecent(limit: Int) throws -> [HealthSnapshot]   // newest first
    func save(_ snapshot: HealthSnapshot) throws              // upserts by date
}
