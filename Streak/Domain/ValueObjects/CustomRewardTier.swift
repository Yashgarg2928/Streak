// Domain/ValueObjects/CustomRewardTier.swift

import Foundation

public enum CustomRewardTier: String, Codable, CaseIterable, Identifiable {
    case snack = "Snack"
    case leisure = "Leisure"
    case experience = "Experience"
    case splurge = "Splurge"
    case milestone = "Milestone"
    case dream = "Dream"
    
    public var id: String { rawValue }
    
    public var emoji: String {
        switch self {
        case .snack: return "🟢"
        case .leisure: return "🔵"
        case .experience: return "🟡"
        case .splurge: return "🟠"
        case .milestone: return "🔴"
        case .dream: return "👑"
        }
    }
    
    public var xpCost: Int {
        switch self {
        case .snack: return 400
        case .leisure: return 1000
        case .experience: return 2000
        case .splurge: return 4000
        case .milestone: return 8000
        case .dream: return 15000
        }
    }
    
    public var intendedDescription: String {
        switch self {
        case .snack: return "Small treats — a gourmet coffee, 30 min YouTube, dessert"
        case .leisure: return "A gaming session, episode binge, a good meal out"
        case .experience: return "A day trip, a movie theatre visit, a restaurant"
        case .splurge: return "A weekend activity, a new book/game, a spa day"
        case .milestone: return "A big personal reward — trip planning, major purchase"
        case .dream: return "Something major you save up for long-term"
        }
    }
}
