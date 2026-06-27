import SwiftUI

/// Modal daily reflection. Deliberately focuses on emotional reaction and
/// awareness rather than loudness - those are the metrics habituation moves.
struct CheckInView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var distress = 4
    @State private var intrusiveness = 5
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Card {
                        ScaleSlider(title: "How much did it bother you today?",
                                    value: $distress,
                                    lowLabel: "Not at all", highLabel: "Severely",
                                    tint: Theme.warmth)
                    }
                    Card {
                        ScaleSlider(title: "How often did you notice it?",
                                    value: $intrusiveness,
                                    lowLabel: "Rarely", highLabel: "Constantly")
                    }
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Anything on your mind? (optional)")
                                .font(.headline).foregroundStyle(Theme.textPrimary)
                            TextField("e.g. stressful day, slept poorly…",
                                      text: $note, axis: .vertical)
                                .lineLimit(2...4)
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surfaceRaised))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }

                    Button("Save check-in") { save() }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 4)
                }
                .padding(18)
            }
            .themedBackground()
            .navigationTitle("Daily check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
            }
            .onAppear {
                if let today = state.todayCheckIn {
                    distress = today.distress
                    intrusiveness = today.intrusiveness
                    note = today.note
                }
            }
        }
    }

    private func save() {
        Haptics.success()
        state.addCheckIn(CheckIn(distress: distress, intrusiveness: intrusiveness, note: note))
        dismiss()
    }
}
