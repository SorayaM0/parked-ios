import SwiftUI
import SwiftData

struct ParkingHistoryView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ParkingSpot.parkedAt, order: .reverse)
    private var parkingSpots: [ParkingSpot]

    private var completedParkingSpots: [ParkingSpot] {
        parkingSpots.filter { !$0.isActive }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if completedParkingSpots.isEmpty {
                emptyHistoryView
            } else {
                historyList
            }
        }
        .navigationTitle("Parking History")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Empty History

    private var emptyHistoryView: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.blue.opacity(0.10))
                    .frame(width: 120, height: 120)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 44))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 8) {
                Text("No Parking History")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(
                    "When you finish a parking session, it will appear here."
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            }

            Spacer()
        }
    }

    // MARK: - History List

    private var historyList: some View {
        List {
            ForEach(completedParkingSpots) { parkingSpot in
                historyCard(parkingSpot)
                    .listRowInsets(
                        EdgeInsets(
                            top: 8,
                            leading: 20,
                            bottom: 8,
                            trailing: 20
                        )
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteParkingSpots)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - History Card

    private func historyCard(
        _ parkingSpot: ParkingSpot
    ) -> some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: "checkmark")
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        parkingSpot.parkedAt.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                    )
                    .font(.headline)

                    Text(
                        parkingSpot.parkedAt.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Completed")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.green.opacity(0.10))
                    .clipShape(Capsule())
            }

            Divider()

            if let completedAt = parkingSpot.completedAt {
                let durationText = parkingDuration(
                    from: parkingSpot.parkedAt,
                    to: completedAt
                )

                HStack(spacing: 20) {
                    historyInfo(
                        icon: "clock",
                        title: "Duration",
                        value: durationText
                    )

                    historyInfo(
                        icon: "checkmark.circle",
                        title: "Returned",
                        value: completedAt.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )
                }
            }

            if !parkingSpot.note.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.blue)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Parking Details")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(parkingSpot.note)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }

            if let expirationDate = parkingSpot.expirationDate {
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .foregroundStyle(.orange)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Parking Expiration")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(
                            expirationDate.formatted(
                                date: .omitted,
                                time: .shortened
                            )
                        )
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                }
            }

            if let imageData = parkingSpot.photoData,
               let uiImage = UIImage(data: imageData) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipped()
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                    )
            }

            Text("Swipe left to delete")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .background(.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }

    // MARK: - History Info

    private func historyInfo(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Duration

    private func parkingDuration(
        from startDate: Date,
        to endDate: Date
    ) -> String {
        let duration = endDate.timeIntervalSince(startDate)

        let totalMinutes = max(
            Int(duration / 60),
            0
        )

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 && minutes > 0 {
            return "\(hours) hr \(minutes) min"
        } else if hours > 0 {
            return "\(hours) hr"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "Less than 1 min"
        }
    }

    // MARK: - Delete History

    private func deleteParkingSpots(
        at offsets: IndexSet
    ) {
        for index in offsets {
            let parkingSpot = completedParkingSpots[index]
            modelContext.delete(parkingSpot)
        }

        do {
            try modelContext.save()
        } catch {
            print(
                "Failed to delete parking history: \(error)"
            )
        }
    }
}

#Preview {
    NavigationStack {
        ParkingHistoryView()
    }
    .modelContainer(
        for: ParkingSpot.self,
        inMemory: true
    )
}
