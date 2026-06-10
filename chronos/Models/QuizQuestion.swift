import Foundation

struct QuizQuestion: Codable, Identifiable, Equatable {
    let id: Int
    let question: String
    let options: [String]
    let correctAnswer: String
    let explanation: String
    let difficulty: String

    enum CodingKeys: String, CodingKey {
        case id, question, options
        case correctAnswer = "correct_answer"
        case explanation, difficulty
    }
}
