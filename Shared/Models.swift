import Foundation

struct FallacyAnalysis: Codable {
    let score: Int
    let verdict: String
    let fallacies: [Fallacy]
}

struct Fallacy: Codable {
    let name: String
    let explanation: String
    let severity: String
}

struct AnalysisRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let text: String
    let analysis: FallacyAnalysis
}
