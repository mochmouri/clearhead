import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {

    // MARK: - State

    private var sharedText: String = ""

    // MARK: - UI

    private let handleView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let previewBox = UIView()
    private let previewLabel = UILabel()
    private let loadingView = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let analysingLabel = UILabel()
    private let resultsScrollView = UIScrollView()
    private let resultsStack = UIStackView()
    private let doneButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSheet()
        buildLayout()
        extractText()
    }

    // MARK: - Sheet configuration

    private func configureSheet() {
        view.backgroundColor = .systemBackground
        if let sheet = sheetPresentationController {
            if #available(iOS 16.0, *) {
                sheet.detents = [.medium(), .large()]
            } else {
                sheet.detents = [.medium(), .large()]
            }
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 20
        }
    }

    // MARK: - Layout

    private func buildLayout() {
        // Handle bar
        handleView.backgroundColor = .tertiaryLabel
        handleView.layer.cornerRadius = 2.5
        handleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(handleView)

        // Header row
        titleLabel.text = "ClearHead"
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .label

        let xImage = UIImage(systemName: "xmark")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        closeButton.setImage(xImage, for: .normal)
        closeButton.tintColor = .secondaryLabel
        closeButton.addTarget(self, action: #selector(dismiss_), for: .touchUpInside)

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), closeButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerRow)

        // Preview box
        previewBox.backgroundColor = .secondarySystemBackground
        previewBox.layer.cornerRadius = 12
        previewBox.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewBox)

        previewLabel.font = .systemFont(ofSize: 13)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 2
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewBox.addSubview(previewLabel)

        // Loading state
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()

        analysingLabel.text = "Analysing..."
        analysingLabel.font = .systemFont(ofSize: 13)
        analysingLabel.textColor = .secondaryLabel

        let loadingStack = UIStackView(arrangedSubviews: [activityIndicator, analysingLabel])
        loadingStack.axis = .horizontal
        loadingStack.spacing = 8
        loadingStack.alignment = .center
        loadingStack.translatesAutoresizingMaskIntoConstraints = false

        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(loadingStack)
        view.addSubview(loadingView)

        NSLayoutConstraint.activate([
            loadingStack.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            loadingStack.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),
            loadingStack.topAnchor.constraint(equalTo: loadingView.topAnchor),
            loadingStack.bottomAnchor.constraint(equalTo: loadingView.bottomAnchor),
        ])

        // Results scroll view (hidden until results arrive)
        resultsScrollView.translatesAutoresizingMaskIntoConstraints = false
        resultsScrollView.isHidden = true
        view.addSubview(resultsScrollView)

        resultsStack.axis = .vertical
        resultsStack.spacing = 0
        resultsStack.translatesAutoresizingMaskIntoConstraints = false
        resultsScrollView.addSubview(resultsStack)

        // Done button
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        doneButton.backgroundColor = .systemBlue
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.layer.cornerRadius = 12
        doneButton.addTarget(self, action: #selector(dismiss_), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            // Handle
            handleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            handleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 36),
            handleView.heightAnchor.constraint(equalToConstant: 5),

            // Header row
            headerRow.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 16),
            headerRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            // Preview box
            previewBox.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 16),
            previewBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            previewBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            previewLabel.topAnchor.constraint(equalTo: previewBox.topAnchor, constant: 12),
            previewLabel.bottomAnchor.constraint(equalTo: previewBox.bottomAnchor, constant: -12),
            previewLabel.leadingAnchor.constraint(equalTo: previewBox.leadingAnchor, constant: 12),
            previewLabel.trailingAnchor.constraint(equalTo: previewBox.trailingAnchor, constant: -12),

            // Loading
            loadingView.topAnchor.constraint(equalTo: previewBox.bottomAnchor, constant: 24),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            loadingView.heightAnchor.constraint(equalToConstant: 44),

            // Results
            resultsScrollView.topAnchor.constraint(equalTo: previewBox.bottomAnchor, constant: 8),
            resultsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultsScrollView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -8),
            resultsStack.topAnchor.constraint(equalTo: resultsScrollView.topAnchor),
            resultsStack.leadingAnchor.constraint(equalTo: resultsScrollView.leadingAnchor),
            resultsStack.trailingAnchor.constraint(equalTo: resultsScrollView.trailingAnchor),
            resultsStack.bottomAnchor.constraint(equalTo: resultsScrollView.bottomAnchor),
            resultsStack.widthAnchor.constraint(equalTo: resultsScrollView.widthAnchor),

            // Done button
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    // MARK: - Text extraction

    private func extractText() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments, !attachments.isEmpty else {
            showError("No content to analyse.")
            return
        }

        let textTypes = ["public.plain-text", "public.text", UTType.plainText.identifier]

        for provider in attachments {
            for typeIdentifier in textTypes {
                if provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                    provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] item, _ in
                        DispatchQueue.main.async {
                            if let text = item as? String, !text.isEmpty {
                                self?.processText(text)
                            } else {
                                self?.showError("Could not read the shared text.")
                            }
                        }
                    }
                    return
                }
            }
        }

        showError("No text content found in the shared item.")
    }

    // MARK: - Analysis

    private func processText(_ text: String) {
        sharedText = text
        let preview = String(text.prefix(100))
        previewLabel.text = text.count > 100 ? preview + "…" : preview

        guard let apiKey = UserDefaults(suiteName: "group.com.clearhead.shared")?.string(forKey: "apiKey"),
              !apiKey.isEmpty else {
            showError("No API key set. Open the ClearHead app to add your Gemini API key.")
            return
        }

        Task {
            do {
                let result = try await GeminiService.shared.analyse(text: text)
                await MainActor.run {
                    self.showResults(result)
                    self.saveToHistory(text: text, analysis: result)
                }
            } catch {
                await MainActor.run {
                    self.showError(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Results rendering

    private func showResults(_ analysis: FallacyAnalysis) {
        loadingView.isHidden = true
        resultsScrollView.isHidden = false
        resultsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        resultsStack.addArrangedSubview(makeScoreView(score: analysis.score, verdict: analysis.verdict))

        if analysis.fallacies.isEmpty {
            resultsStack.addArrangedSubview(makeEmptyView())
        } else {
            resultsStack.addArrangedSubview(makeDivider())
            for (index, fallacy) in analysis.fallacies.enumerated() {
                resultsStack.addArrangedSubview(makeFallacyRow(fallacy))
                if index < analysis.fallacies.count - 1 {
                    resultsStack.addArrangedSubview(makeDivider())
                }
            }
        }
    }

    private func makeScoreView(score: Int, verdict: String) -> UIView {
        let container = UIView()

        let scoreLabel = UILabel()
        scoreLabel.text = "\(score)"
        scoreLabel.font = .systemFont(ofSize: 48, weight: .thin)
        scoreLabel.textColor = .label

        let maxLabel = UILabel()
        maxLabel.text = "/100"
        maxLabel.font = .systemFont(ofSize: 16)
        maxLabel.textColor = .secondaryLabel

        let scoreRow = UIStackView(arrangedSubviews: [scoreLabel, maxLabel])
        scoreRow.axis = .horizontal
        scoreRow.alignment = .lastBaseline
        scoreRow.spacing = 2
        scoreRow.translatesAutoresizingMaskIntoConstraints = false

        let verdictLabel = UILabel()
        verdictLabel.text = verdict
        verdictLabel.font = .systemFont(ofSize: 13)
        verdictLabel.textColor = .secondaryLabel
        verdictLabel.textAlignment = .center
        verdictLabel.numberOfLines = 0
        verdictLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(scoreRow)
        container.addSubview(verdictLabel)

        NSLayoutConstraint.activate([
            scoreRow.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            scoreRow.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            verdictLabel.topAnchor.constraint(equalTo: scoreRow.bottomAnchor, constant: 8),
            verdictLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            verdictLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            verdictLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
        return container
    }

    private func makeDivider() -> UIView {
        let line = UIView()
        line.backgroundColor = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([line.heightAnchor.constraint(equalToConstant: 0.5)])
        return line
    }

    private func makeFallacyRow(_ fallacy: Fallacy) -> UIView {
        let container = UIView()

        let nameLabel = UILabel()
        nameLabel.text = fallacy.name
        nameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = .label

        let explanationLabel = UILabel()
        explanationLabel.text = fallacy.explanation
        explanationLabel.font = .systemFont(ofSize: 13)
        explanationLabel.textColor = .secondaryLabel
        explanationLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [nameLabel, explanationLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let pill = makeSeverityPill(fallacy.severity)

        container.addSubview(textStack)
        container.addSubview(pill)

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            textStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: pill.leadingAnchor, constant: -12),
            textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            pill.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            pill.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
        ])
        return container
    }

    private func makeSeverityPill(_ severity: String) -> UIView {
        let pill = UIView()
        pill.layer.cornerRadius = 8
        pill.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false

        switch severity.lowercased() {
        case "high":
            pill.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
            label.textColor = .systemRed
            label.text = "High"
        case "medium":
            pill.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
            label.textColor = .systemOrange
            label.text = "Medium"
        default:
            pill.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
            label.textColor = .systemGreen
            label.text = "Low"
        }

        pill.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: pill.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -4),
            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -8),
        ])
        return pill
    }

    private func makeEmptyView() -> UIView {
        let container = UIView()

        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle"))
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "No fallacies detected"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(imageView)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 40),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24),
        ])
        return container
    }

    // MARK: - Error state

    private func showError(_ message: String) {
        loadingView.isHidden = true
        resultsScrollView.isHidden = false
        resultsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let container = UIView()
        let label = UILabel()
        label.text = message
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -24),
        ])
        resultsStack.addArrangedSubview(container)
    }

    // MARK: - History persistence

    private func saveToHistory(text: String, analysis: FallacyAnalysis) {
        let record = AnalysisRecord(id: UUID(), date: Date(), text: text, analysis: analysis)
        let defaults = UserDefaults(suiteName: "group.com.clearhead.shared")

        var records: [AnalysisRecord] = []
        if let data = defaults?.data(forKey: "analysisHistory"),
           let existing = try? JSONDecoder().decode([AnalysisRecord].self, from: data) {
            records = existing
        }
        records.append(record)
        if records.count > 20 { records = Array(records.suffix(20)) }

        if let data = try? JSONEncoder().encode(records) {
            defaults?.set(data, forKey: "analysisHistory")
        }
    }

    // MARK: - Actions

    @objc private func dismiss_() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
