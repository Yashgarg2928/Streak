// Application/UseCases/Notifications/GeminiNotificationService.swift

import Foundation

public final class GeminiNotificationService {
    public static let shared = GeminiNotificationService()
    private init() {}

    /// Rolling alias for Google's newest Flash model, so retiring a model version doesn't
    /// silently break AI notifications again (gemini-1.5-flash was shut down in 2025).
    private static let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent")!

    private func makeRequest(apiKey: String, prompt: String) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Key goes in a header rather than the URL so it never lands in URL logs.
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        let body: [String: Any] = ["contents": [["parts": [["text": prompt]]]]]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    public func testApiKey(_ apiKey: String) async throws -> String {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            throw NSError(domain: "GeminiService", code: 400, userInfo: [NSLocalizedDescriptionKey: "API Key cannot be empty."])
        }

        let promptText = "Generate a single 1-sentence spicy notification to encourage a user to do their daily habits. Keep it funny, punchy, under 100 characters. Return plain text only."
        let request = try makeRequest(apiKey: cleanKey, prompt: promptText)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResp = response as? HTTPURLResponse else {
            throw NSError(domain: "GeminiService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server."])
        }

        guard httpResp.statusCode == 200 else {
            throw NSError(domain: "GeminiService", code: httpResp.statusCode, userInfo: [NSLocalizedDescriptionKey: "Gemini API Error (Status \(httpResp.statusCode)). Check your API key."])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw NSError(domain: "GeminiService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response from Gemini."])
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func generateDynamicNotification(
        apiKey: String,
        persona: String,
        streak: Int,
        level: Int,
        title: String,
        habitTitles: [String],
        touchpoint: NotificationTouchpoint
    ) async -> NotificationMessage? {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else { return nil }

        let touchpointDescription: String
        switch touchpoint {
        case .morningHype: touchpointDescription = "Morning hype notification (8:00 AM)"
        case .middayNudge: touchpointDescription = "Mid-day check-in nudge (3:00 PM)"
        case .planningAlert: touchpointDescription = "Nightly reminder to plan tomorrow's tasks"
        case .emergencyCutoff: touchpointDescription = "Emergency warning 1 hour before the active day ends"
        }

        let habitsList = habitTitles.prefix(3).joined(separator: ", ")
        let promptText = """
        Write a short iOS push notification for a user on a self-improvement app.
        Context:
        - Touchpoint: \(touchpointDescription)
        - Persona / Style: \(persona) (e.g. savage roast, drill sergeant, rpg lore, zen)
        - User Current Streak: \(streak) days
        - User Level: Level \(level) "\(title)"
        - Active Habits: \(habitsList.isEmpty ? "Daily Tasks" : habitsList)

        Instructions:
        Return ONLY a JSON object with two fields: "title" (short emoji + title under 30 chars) and "body" (punchy message under 100 chars).
        Example: {"title": "🔥 Streak in Danger!", "body": "Your 7-day streak needs 2 hrs DSA. Get off social media!"}
        """

        do {
            let request = try makeRequest(apiKey: cleanKey, prompt: promptText)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else { return nil }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let rawText = parts.first?["text"] as? String else { return nil }

            // Extract JSON from response
            let cleanedText = rawText
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let jsonData = cleanedText.data(using: .utf8),
                  let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: String],
                  let msgTitle = parsed["title"],
                  let msgBody = parsed["body"] else { return nil }

            return NotificationMessage(title: msgTitle, body: msgBody)
        } catch {
            return nil
        }
    }
}
