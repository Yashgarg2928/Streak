// Domain/ValueObjects/GoalType.swift
// Pure Swift — no UIKit, SwiftUI, or SwiftData imports

import Foundation

enum GoalType: String, Codable, Equatable, CaseIterable {
    case consistencyLinked  // progress = streak or % green days for linked category
    case milestoneBased     // user logs progress manually each day
    case custom             // user defines increment logic
}
