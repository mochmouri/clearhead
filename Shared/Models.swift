import Foundation

struct FallacyAnalysis: Codable {
    let score: Int
    let verdict: String
    let fallacies: [Fallacy]
    let suggestion: String?
}

struct Fallacy: Codable, Identifiable {
    var id: String { name }
    let name: String
    let explanation: String
    let severity: String
    let quote: String?
}

struct AnalysisRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let text: String
    let analysis: FallacyAnalysis
    let source: String?  // "manual" or "shared"
}
