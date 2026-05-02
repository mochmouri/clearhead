import SwiftUI

private let sharedDefaults = UserDefaults.standard

struct ContentView: View {
    @State private var apiKey: String = sharedDefaults.string(forKey: "apiKey") ?? ""
    @State private var apiKeySaved: Bool = false
    @State private var manualText: String = ""
    @State private var isAnalysing: Bool = false
    @State private var manualResult: AnalysisRecord? = nil
    @State private var analysisError: String? = nil
    @State private var history: [AnalysisRecord] = []

    var body: some View {
        NavigationView {
            List {
                // MARK: API Key
                Section {
                    SecureField("Paste your API key here", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onAppear {
                            apiKey = sharedDefaults.string(forKey: "apiKey") ?? ""
                        }

                    Button(action: saveAPIKey) {
                        HStack {
                            Text(apiKeySaved ? "Saved!" : "Save API Key")
                                .foregroundColor(apiKeySaved ? .green : .blue)
                            if apiKeySaved {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .disabled(apiKey.isEmpty)

                    Link("Get a free API key →",
                         destination: URL(string: "https://aistudio.google.com")!)
                        .font(.footnote)
                        .foregroundColor(.blue)
                } header: {
                    Text("Gemini API Key")
                } footer: {
                    Text("Your key is stored on-device and shared only with the Gemini API.")
                }

                // MARK: Manual Analysis
                Section {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $manualText)
                            .frame(minHeight: 100)
                            .autocorrectionDisabled()
                        if manualText.isEmpty {
                            Text("Paste or type text to analyse…")
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }

                    Button {
                        Task { await runManualAnalysis() }
                    } label: {
                        if isAnalysing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Analysing…")
                            }
                        } else {
                            Text("Analyse")
                        }
                    }
                    .disabled(manualText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAnalysing)
                } header: {
                    Text("Analyse Text")
                }

                // MARK: History
                Section {
                    if history.isEmpty {
                        Text("No analyses yet. Share text from any app to get started.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(history) { record in
                            NavigationLink(destination: AnalysisDetailView(record: record)) {
                                HistoryRow(record: record)
                            }
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
            .sheet(item: $manualResult) { record in
                NavigationView {
                    AnalysisDetailView(record: record)
                        .navigationBarItems(trailing: Button("Done") { manualResult = nil })
                }
            }
            .alert("Analysis Failed", isPresented: Binding(
                get: { analysisError != nil },
                set: { if !$0 { analysisError = nil } }
            )) {
                Button("OK") { analysisError = nil }
            } message: {
                Text(analysisError ?? "")
            }
        }
    }

    // MARK: - Actions

    private func saveAPIKey() {
        sharedDefaults.set(apiKey, forKey: "apiKey")
        apiKeySaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            apiKeySaved = false
        }
    }

    @MainActor
    private func runManualAnalysis() async {
        isAnalysing = true
        let text = manualText
        do {
            let analysis = try await GeminiService.shared.analyse(text: text, source: "manual")
            let record = AnalysisRecord(id: UUID(), date: Date(), text: text, analysis: analysis, source: "manual")
            persistRecord(record)
            isAnalysing = false
            manualResult = record
            manualText = ""
        } catch {
            isAnalysing = false
            analysisError = error.localizedDescription
        }
    }

    private func persistRecord(_ record: AnalysisRecord) {
        var records: [AnalysisRecord] = []
        if let data = sharedDefaults.data(forKey: "analysisHistory"),
           let existing = try? JSONDecoder().decode([AnalysisRecord].self, from: data) {
            records = existing
        }
        records.append(record)
        if records.count > 20 { records = Array(records.suffix(20)) }
        if let data = try? JSONEncoder().encode(records) {
            sharedDefaults.set(data, forKey: "analysisHistory")
        }
        loadHistory()
    }

    private func loadHistory() {
        guard let data = sharedDefaults.data(forKey: "analysisHistory"),
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
            sharedDefaults.set(data, forKey: "analysisHistory")
        }
    }
}

// MARK: - Analysis Detail View

struct AnalysisDetailView: View {
    let record: AnalysisRecord

    private var isManual: Bool { record.source == "manual" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Score card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(record.analysis.score)")
                            .font(.system(size: 48, weight: .thin))
                        Text("/100")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let source = record.source {
                            Text(source == "manual" ? "Manual" : "Shared")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(8)
                        }
                    }
                    Text(record.analysis.verdict)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                // Original text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text")
                        .font(.headline)
                    Text(record.text)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                // Fallacies
                if record.analysis.fallacies.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        Text("No fallacies detected")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                } else {
                    Text("Fallacies Detected")
                        .font(.headline)
                    ForEach(record.analysis.fallacies) { fallacy in
                        FallacyCard(fallacy: fallacy)
                    }
                }

                // Suggestion
                if let suggestion = record.analysis.suggestion, !suggestion.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isManual ? "How to Improve" : "Reply Direction")
                            .font(.headline)
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle(isManual ? "Analysis" : "Inbound Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Fallacy Card

struct FallacyCard: View {
    let fallacy: Fallacy

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(fallacy.name)
                    .font(.subheadline.weight(.medium))
                Spacer()
                SeverityPill(severity: fallacy.severity)
            }
            Text(fallacy.explanation)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if let quote = fallacy.quote, !quote.isEmpty {
                Text("\u{201C}\(quote)\u{201D}")
                    .font(.footnote.italic())
                    .foregroundColor(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Severity Pill

struct SeverityPill: View {
    let severity: String

    var body: some View {
        let (color, label) = style()
        Text(label)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }

    private func style() -> (Color, String) {
        switch severity.lowercased() {
        case "high":   return (Color(UIColor.systemRed), "High")
        case "medium": return (Color(UIColor.systemOrange), "Medium")
        default:       return (Color(UIColor.systemGreen), "Low")
        }
    }
}

// MARK: - History Row

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
            HStack(spacing: 6) {
                Text(Self.dateFormatter.string(from: record.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let source = record.source {
                    Text("·")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(source == "manual" ? "Manual" : "Shared")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 70 { return Color(UIColor.systemGreen) }
        if score >= 40 { return Color(UIColor.systemOrange) }
        return Color(UIColor.systemRed)
    }
}
