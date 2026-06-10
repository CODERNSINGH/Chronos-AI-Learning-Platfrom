import Foundation

enum Constants {
    // MARK: - Groq API
    static let groqBaseURL = "https://api.groq.com/openai/v1/chat/completions"
    static let defaultGroqModel = "llama-3.3-70b-versatile"
    static let groqFallbackModel = "llama3-70b-8192"

    /// Free-tier API key shipped with the app. Users can override it in Settings.
    static let defaultAPIKey = ""

    // MARK: - Keychain
    static let keychainService = "com.codernsingh.chronos"
    static let apiKeyAccount = "groq_api_key"

    // MARK: - UserDefaults
    static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    static let usernameKey = "username"
    static let avatarKey = "avatar"
    static let notificationsEnabledKey = "notificationsEnabled"
    static let notificationTimeKey = "notificationTime"
    static let lastQuizDateKey = "lastQuizDate"
    static let streakCountKey = "streakCount"
    static let bestStreakKey = "bestStreak"
    static let favoriteTopicKey = "favoriteTopic"
    static let selectedModelKey = "selectedGroqModel"

    // MARK: - XP / Levels
    struct Level {
        let level: Int
        let title: String
        let xpRequired: Int
        let xpUpperBound: Int

        var xpForNextLevel: Int {
            xpUpperBound - xpRequired
        }
    }

    static let levels: [Level] = [
        Level(level: 1,  title: "Code Initiate",       xpRequired: 0,    xpUpperBound: 100),
        Level(level: 2,  title: "Array Apprentice",    xpRequired: 101,  xpUpperBound: 250),
        Level(level: 3,  title: "Stack Scholar",       xpRequired: 251,  xpUpperBound: 500),
        Level(level: 4,  title: "Tree Traverser",      xpRequired: 501,  xpUpperBound: 900),
        Level(level: 5,  title: "Graph Explorer",      xpRequired: 901,  xpUpperBound: 1400),
        Level(level: 6,  title: "DP Disciple",         xpRequired: 1401, xpUpperBound: 2000),
        Level(level: 7,  title: "Algorithm Architect", xpRequired: 2001, xpUpperBound: 3000),
        Level(level: 8,  title: "Segment Sage",        xpRequired: 3001, xpUpperBound: 4500),
        Level(level: 9,  title: "Binary Master",       xpRequired: 4501, xpUpperBound: 6500),
        Level(level: 10, title: "Chronos Champion",    xpRequired: 6501, xpUpperBound: 99999)
    ]

    // MARK: - XP Rewards
    static let xpPerCorrect = 20
    static let xpSpeedBonus = 10           // under 10 seconds
    static let xpPerfectScoreBonus = 50

    // MARK: - Quiz
    static let questionsPerQuiz = 5
    static let secondsPerQuestion = 60
    static let speedBonusThreshold = 10

    // MARK: - Avatars
    static let avatars = ["🐱", "🦊", "🐼", "🦁", "🐯", "🐸", "🦉", "🐺"]

    // MARK: - App Info
    static let appName = "CHRONOS"
    static let appTagline = "Master DSA. One concept at a time."
    static let appVersion = "1.0"
}

// MARK: - Groq model catalog

struct GroqModel: Identifiable, Hashable {
    let id: String          // API identifier
    let displayName: String
    let provider: String
    let summary: String
    let tier: Tier          // chat, audio, classifier

    enum Tier: String, Hashable {
        case chat
        case audio
        case classifier
        case multimodal
    }

    var icon: String {
        switch provider {
        case "Groq":          return "bolt.horizontal.circle.fill"
        case "Meta":          return "f.square.fill"
        case "OpenAI":        return "brain.head.profile"
        case "Alibaba Cloud": return "cloud.fill"
        case "Canopy Labs":   return "waveform"
        default:              return "cpu"
        }
    }
}

extension Constants {
    /// Curated catalog of Groq-hosted models. Users pick one in onboarding / settings.
    static let groqModels: [GroqModel] = [
        // Groq
        GroqModel(id: "groq/compound",
                  displayName: "Compound",
                  provider: "Groq",
                  summary: "Web-search enabled reasoning",
                  tier: .chat),
        GroqModel(id: "groq/compound-mini",
                  displayName: "Compound Mini",
                  provider: "Groq",
                  summary: "Lightweight search agent",
                  tier: .chat),

        // Meta
        GroqModel(id: "llama-3.1-8b-instant",
                  displayName: "Llama 3.1 8B Instant",
                  provider: "Meta",
                  summary: "Ultra-fast small model",
                  tier: .chat),
        GroqModel(id: "llama-3.3-70b-versatile",
                  displayName: "Llama 3.3 70B Versatile",
                  provider: "Meta",
                  summary: "Powerful and versatile (default)",
                  tier: .chat),
        GroqModel(id: "meta-llama/llama-4-scout-17b-16e-instruct",
                  displayName: "Llama 4 Scout 17B",
                  provider: "Meta",
                  summary: "Latest Llama 4 MoE",
                  tier: .chat),
        GroqModel(id: "meta-llama/llama-prompt-guard-2-22m",
                  displayName: "Prompt Guard 22M",
                  provider: "Meta",
                  summary: "Tiny prompt-injection classifier",
                  tier: .classifier),
        GroqModel(id: "meta-llama/llama-prompt-guard-2-86m",
                  displayName: "Prompt Guard 86M",
                  provider: "Meta",
                  summary: "Prompt-injection classifier",
                  tier: .classifier),

        // OpenAI
        GroqModel(id: "openai/gpt-oss-120b",
                  displayName: "GPT OSS 120B",
                  provider: "OpenAI",
                  summary: "Open-source flagship",
                  tier: .chat),
        GroqModel(id: "openai/gpt-oss-20b",
                  displayName: "GPT OSS 20B",
                  provider: "OpenAI",
                  summary: "Mid-size open model",
                  tier: .chat),
        GroqModel(id: "openai/gpt-oss-safeguard-20b",
                  displayName: "GPT OSS Safeguard 20B",
                  provider: "OpenAI",
                  summary: "Safety-tuned variant",
                  tier: .chat),
        GroqModel(id: "whisper-large-v3",
                  displayName: "Whisper Large v3",
                  provider: "OpenAI",
                  summary: "High accuracy transcription",
                  tier: .audio),
        GroqModel(id: "whisper-large-v3-turbo",
                  displayName: "Whisper Large v3 Turbo",
                  provider: "OpenAI",
                  summary: "Fast transcription",
                  tier: .audio),

        // Alibaba
        GroqModel(id: "qwen/qwen3-32b",
                  displayName: "Qwen 3 32B",
                  provider: "Alibaba Cloud",
                  summary: "Multilingual reasoning",
                  tier: .chat),

        // Canopy Labs
        GroqModel(id: "canopylabs/orpheus-arabic-saudi",
                  displayName: "Orpheus Arabic (SA)",
                  provider: "Canopy Labs",
                  summary: "Arabic text-to-speech",
                  tier: .audio),
        GroqModel(id: "canopylabs/orpheus-vl-english",
                  displayName: "Orpheus VL English",
                  provider: "Canopy Labs",
                  summary: "Voice + visual English",
                  tier: .multimodal)
    ]

    /// Returns a model by id, or the default model.
    static func groqModel(id: String) -> GroqModel {
        groqModels.first(where: { $0.id == id }) ?? groqModels.first { $0.id == defaultGroqModel } ?? groqModels[0]
    }

    /// Models grouped by provider for picker UIs.
    static var groqModelsByProvider: [(provider: String, models: [GroqModel])] {
        let dict = Dictionary(grouping: groqModels, by: \.provider)
        return dict.keys.sorted().map { ($0, dict[$0] ?? []) }
    }
}
