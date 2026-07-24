// Application/UseCases/Notifications/SpicyNotificationTemplates.swift

import Foundation

public struct NotificationMessage {
    public let title: String
    public let body: String
}

public enum NotificationTouchpoint {
    case morningHype
    case middayNudge
    case planningAlert
    case emergencyCutoff
}

public struct SpicyNotificationTemplates {
    public static func message(
        for touchpoint: NotificationTouchpoint,
        persona: String,
        streak: Int,
        level: Int,
        title: String,
        pendingTasksCount: Int
    ) -> NotificationMessage {
        switch persona {
        case "goggins":
            return gogginsMessage(touchpoint: touchpoint, streak: streak, level: level, pendingCount: pendingTasksCount)
        case "rpg":
            return rpgMessage(touchpoint: touchpoint, streak: streak, level: level, title: title, pendingCount: pendingTasksCount)
        case "zen":
            return zenMessage(touchpoint: touchpoint, streak: streak, pendingCount: pendingTasksCount)
        default: // "savage"
            return savageMessage(touchpoint: touchpoint, streak: streak, level: level, pendingCount: pendingTasksCount)
        }
    }

    private static func savageMessage(
        touchpoint: NotificationTouchpoint,
        streak: Int,
        level: Int,
        pendingCount: Int
    ) -> NotificationMessage {
        switch touchpoint {
        case .morningHype:
            return NotificationMessage(
                title: "🔥 Rise & Grind, Level \(level)",
                body: "Your \(streak)-day streak didn't build itself. You've got tasks waiting — don't slack now!"
            )
        case .middayNudge:
            return NotificationMessage(
                title: "⚠️ Procrastination Alert!",
                body: "You still have \(pendingCount) task\(pendingCount == 1 ? "" : "s") untouched. Your Level \(level) badge is judging you."
            )
        case .planningAlert:
            return NotificationMessage(
                title: "⏰ Planning Deadline Approaching!",
                body: "30 minutes left to lock in your daily tasks! Don't let your day turn RED."
            )
        case .emergencyCutoff:
            return NotificationMessage(
                title: "🚨 Active Day Ending Soon!",
                body: "\(pendingCount) task\(pendingCount == 1 ? "" : "s") still incomplete! Finish them before midnight or take the −30 XP hit!"
            )
        }
    }

    private static func gogginsMessage(
        touchpoint: NotificationTouchpoint,
        streak: Int,
        level: Int,
        pendingCount: Int
    ) -> NotificationMessage {
        switch touchpoint {
        case .morningHype:
            return NotificationMessage(
                title: "⚔️ Zero Excuses Today",
                body: "\(streak) days strong. Nobody is coming to do the work for you. Execute your tasks!"
            )
        case .middayNudge:
            return NotificationMessage(
                title: "⚔️ Stay Hard!",
                body: "\(pendingCount) task\(pendingCount == 1 ? "" : "s") remaining. Push through the resistance and get it done."
            )
        case .planningAlert:
            return NotificationMessage(
                title: "⏰ Lock In Your Commitments",
                body: "Planning deadline is near. Set your targets or accept defeat. Choose discipline."
            )
        case .emergencyCutoff:
            return NotificationMessage(
                title: "🚨 Final Stand",
                body: "Day is wrapping up with \(pendingCount) unfinished task\(pendingCount == 1 ? "" : "s"). Finish strong or pay the XP penalty!"
            )
        }
    }

    private static func rpgMessage(
        touchpoint: NotificationTouchpoint,
        streak: Int,
        level: Int,
        title: String,
        pendingCount: Int
    ) -> NotificationMessage {
        switch touchpoint {
        case .morningHype:
            return NotificationMessage(
                title: "🎮 Quest Awaits, \(title)!",
                body: "Level \(level) Hero, your \(streak)-day streak flame burns bright. Enter the arena and claim today's XP!"
            )
        case .middayNudge:
            return NotificationMessage(
                title: "⚔️ Unfinished Quests Remain!",
                body: "\(pendingCount) quest\(pendingCount == 1 ? "" : "s") pending! Clear them out to earn bonus XP and level up."
            )
        case .planningAlert:
            return NotificationMessage(
                title: "📜 Prepare Your Quest Log",
                body: "Planning window closes in 30 mins! Register your daily targets before the realm locks."
            )
        case .emergencyCutoff:
            return NotificationMessage(
                title: "👾 Dungeon Gate Closing!",
                body: "Your streak is under attack! Clear \(pendingCount) remaining task\(pendingCount == 1 ? "" : "s") to shield your XP."
            )
        }
    }

    private static func zenMessage(
        touchpoint: NotificationTouchpoint,
        streak: Int,
        pendingCount: Int
    ) -> NotificationMessage {
        switch touchpoint {
        case .morningHype:
            return NotificationMessage(
                title: "🌱 A Fresh Start Today",
                body: "Consistency is built with quiet effort. You're on a \(streak)-day streak — enjoy the process."
            )
        case .middayNudge:
            return NotificationMessage(
                title: "🧘 Pause & Refocus",
                body: "You have \(pendingCount) task\(pendingCount == 1 ? "" : "s") remaining today. Take a deep breath and take one step."
            )
        case .planningAlert:
            return NotificationMessage(
                title: "⏰ Mindful Planning",
                body: "Take a minute to reflect and set your intentions for tomorrow before the deadline."
            )
        case .emergencyCutoff:
            return NotificationMessage(
                title: "🌙 Evening Reflection",
                body: "Active day is drawing to a close. Wrap up your remaining tasks to finish today peacefully."
            )
        }
    }
}
