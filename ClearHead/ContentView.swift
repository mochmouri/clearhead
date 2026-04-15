import SwiftUI

private let sharedDefaults = UserDefaults(suiteName: "group.com.clearhead.shared")

struct ContentView: View {
    @State private var apiKey: String = sharedDefaults?.string(forKey: "apiKey") ?? ""
    @State private var history: [AnalysisRecord] = []

    var body: some View {
        NavigationView {
            List {
                Section {
                    SecureField("Paste your API key here", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: apiKey) { newValue in
                            sharedDefaults?.set(newValue, forKey: "apiKey")
                        }

                    Link("Get a free API key →",
                         destination: URL(string: "https://aistudio.google.com")!)
                        .font(.footnote)
                        .foregroundColor(.blue)
                } header: {
                    Text("Gemini API Key")
                } footer: {
                    Text("Your key is stored on-device and shared only with the Gemini API.")
                }

                Section {
                    if history.isEmpty {
                        Text("No analyses yet. Share text from any app to get started.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(history) { record in
                            HistoryRow(record: record)
                        }
                        .onDelete(perform: deleteRecords)
                    }
                } header: {
                    Text("Recent Analyses")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("ClearHead")
            .onAppear(perform: loadHistory)
        }
    }

    private func loadHistory() {
        guard let data = sharedDefaults?.data(forKey: "analysisHistory"),
              let records = try? JSONDecoder().decode([AnalysisRecord].self, from: data) else {
            history = []
            return
        }
        history = Array(records.suffix(20).reversed())
    }

    private func deleteRecords(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        let chronological = Array(history.reversed())
        if let data = try? JSONEncoder().encode(chronological) {
            sharedDefaults?.set(data, forKey: "analysisHistory")
        }
    }
}

struct HistoryRow: View {
    let record: AnalysisRecord

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                let preview = String(record.text.prefix(60))
                Text(record.text.count > 60 ? preview + "…" : preview)
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                Text("\(record.analysis.score)")
                    .font(.headline.monospacedDigit())
                    .foregroundColor(scoreColor(record.analysis.score))
            }
            Text(Self.dateFormatter.string(from: record.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 70 { return Color(UIColor.systemGreen) }
        if score >= 40 { return Color(UIColor.systemOrange) }
        return Color(UIColor.systemRed)
    }
}
