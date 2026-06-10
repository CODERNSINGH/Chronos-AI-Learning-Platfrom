import SwiftUI

struct ModelPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    let currentModelID: String
    let onSelect: (GroqModel) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                ChronosTheme.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        searchField
                        ForEach(filteredGroups, id: \.provider) { group in
                            providerSection(provider: group.provider, models: group.models)
                        }
                        Spacer().frame(height: 30)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu.fill")
                        Text("LLM MODEL")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .tracking(2.5)
                    }
                    .foregroundStyle(ChronosTheme.amber)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(ChronosTheme.amber)
                }
            }
        }
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(ChronosTheme.textTertiary)
            TextField("Search models…", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(ChronosTheme.textPrimary)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(ChronosTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ChronosTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ChronosTheme.surfaceBorder, lineWidth: 1)
        )
    }

    private func providerSection(provider: String, models: [GroqModel]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: models.first?.icon ?? "cpu")
                    .font(.system(size: 11, weight: .bold))
                Text(provider.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
            }
            .foregroundStyle(ChronosTheme.amber)

            VStack(spacing: 8) {
                ForEach(models) { model in
                    modelRow(model)
                }
            }
        }
    }

    private func modelRow(_ model: GroqModel) -> some View {
        let isCurrent = model.id == currentModelID
        return Button {
            onSelect(model)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isCurrent ? ChronosTheme.amber.opacity(0.25) : ChronosTheme.surface)
                        .frame(width: 40, height: 40)
                    Image(systemName: model.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isCurrent ? ChronosTheme.amber : ChronosTheme.textSecondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(model.displayName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(ChronosTheme.textPrimary)
                        if model.id == Constants.defaultGroqModel {
                            Text("DEFAULT")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .tracking(1)
                                .foregroundStyle(ChronosTheme.amber)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(ChronosTheme.amber.opacity(0.18)))
                        }
                    }
                    Text(model.summary)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(ChronosTheme.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                if isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(ChronosTheme.amber)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(ChronosTheme.textTertiary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isCurrent ? ChronosTheme.amber.opacity(0.08) : ChronosTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isCurrent ? ChronosTheme.amber.opacity(0.4) : ChronosTheme.surfaceBorder,
                            lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filtering

    private var filteredGroups: [(provider: String, models: [GroqModel])] {
        if query.isEmpty { return Constants.groqModelsByProvider }
        let q = query.lowercased()
        return Constants.groqModelsByProvider.compactMap { group in
            let matched = group.models.filter {
                $0.displayName.lowercased().contains(q) ||
                $0.provider.lowercased().contains(q) ||
                $0.summary.lowercased().contains(q)
            }
            return matched.isEmpty ? nil : (group.provider, matched)
        }
    }
}
