// Domain/ValueObjects/PlayerTitle.swift

import Foundation

public struct PlayerTitle: Equatable, Identifiable {
    public var id: String { name }
    public let name: String
    public let emoji: String
    public let subtitle: String
    public let minLevel: Int
    
    public static let allTitles: [PlayerTitle] = [
        PlayerTitle(name: "Seedling",     emoji: "🌱", subtitle: "Just getting started", minLevel: 1),
        PlayerTitle(name: "Sparked",      emoji: "🔥", subtitle: "Something's igniting", minLevel: 5),
        PlayerTitle(name: "In Motion",    emoji: "🏃", subtitle: "Momentum is building", minLevel: 10),
        PlayerTitle(name: "Committed",    emoji: "💪", subtitle: "This is becoming a lifestyle", minLevel: 15),
        PlayerTitle(name: "Builder",      emoji: "🧱", subtitle: "Consistency is your superpower", minLevel: 20),
        PlayerTitle(name: "Charged",      emoji: "⚡", subtitle: "Running on discipline", minLevel: 25),
        PlayerTitle(name: "Focused",      emoji: "🎯", subtitle: "Distraction can't reach you", minLevel: 30),
        PlayerTitle(name: "Resilient",    emoji: "🛡", subtitle: "Setbacks are just data", minLevel: 40),
        PlayerTitle(name: "Elite",        emoji: "🏆", subtitle: "You've outpaced most humans", minLevel: 50),
        PlayerTitle(name: "Champion",     emoji: "🌟", subtitle: "Top 1% of consistent people", minLevel: 60),
        PlayerTitle(name: "Legend",       emoji: "🔱", subtitle: "Your discipline is legendary", minLevel: 75),
        PlayerTitle(name: "Transcendent", emoji: "☄️", subtitle: "Beyond ordinary limits", minLevel: 90),
        PlayerTitle(name: "Immortal",     emoji: "👑", subtitle: "You are the system", minLevel: 100)
    ]
    
    public static func title(for level: Int) -> PlayerTitle {
        let sorted = allTitles.sorted(by: { $0.minLevel > $1.minLevel })
        return sorted.first(where: { level >= $0.minLevel }) ?? allTitles[0]
    }
}
