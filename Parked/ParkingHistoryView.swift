import SwiftUI
import SwiftData

struct ParkingHistoryView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ParkingSpot.parkedAt, order: .reverse)
    private var parkingSpots: [ParkingSpot]

    private let pageBackground = Color(
        red: 0.965,
        green: 0.957,
        blue: 0.933
    )

    private let ink = Color(
        red: 0.08,
        green: 0.12,
        blue: 0.14
    )

    private let parkedGreen = Color(
        red: 0.10,
        green: 0.42,
        blue: 0.31
    )

    private let softGreen = Color(
        red: 0.89,
        green: 0.94,
        blue: 0.90
    )

    private let warmOrange = Color(
        red: 0.86,
        green: 0.48,
        blue: 0.18
    )

    private var completedParkingSpots: [ParkingSpot] {
        parkingSpots.filter { !$0.isActive }
    }

    var body: some View {
        ZStack {
            pageBackground
                .ignoresSafeArea()

            if completedParkingSpots.isEmpty {
                emptyHistoryView
            } else {
                historyList
            }
        }
        .navigationTitle("Parking History")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(pageBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(parkedGreen)
    }

    // MARK: - Empty History

    private var emptyHistoryView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 22) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 24,
                        style: .continuous
                    )
                    .fill(ink)
                    .frame(width: 84, height: 84)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(pageBackground)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("No parking history yet.")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(ink)

                    Text(
                        "Finished parking sessions will appear here so you can look back at where and when you parked."
                    )
                    .font(.system(size: 16))
                    .foregroundStyle(ink.opacity(0.58))
                    .lineSpacing(4)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.bottom, 40)
    }

    // MARK: - History List

    private var historyList: some View {
        List {
            Section {
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

            } header: {
                historyHeader
                    .textCase(nil)
                    .listRowInsets(
                        EdgeInsets(
                            top: 8,
                            leading: 20,
                            bottom: 8,
                            trailing: 20
                        )
                    )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    // MARK: - History Header

    private var historyHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Past parking")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(ink)

            Text(historyCountText)
                .font(.system(size: 13))
                .foregroundStyle(ink.opacity(0.5))
        }
        .padding(.bottom, 4)
    }

    private var historyCountText: String {
        if completedParkingSpots.count == 1 {
            return "1 completed parking session"
        }

        return "\(completedParkingSpots.count) completed parking sessions"
    }

    // MARK: - History Card

    private func historyCard(
        _ parkingSpot: ParkingSpot
    ) -> some View {
        let parkedTime = parkingSpot.parkedAt.formatted(
            date: .omitted,
            time: .shortened
        )

        return VStack(alignment: .leading, spacing: 18) {

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 13,
                        style: .continuous
                    )
                    .fill(softGreen)
                    .frame(width: 44, height: 44)

                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(parkedGreen)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        parkingSpot.parkedAt.formatted(
                            date: .abbreviated,
                            time: .omitted
                        )
                    )
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ink)

                    Text("Parked at \(parkedTime)")
                        .font(.system(size: 13))
                        .foregroundStyle(ink.opacity(0.52))
                }

                Spacer()

                Text("Completed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(parkedGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(softGreen)
                    .clipShape(Capsule())
            }

            Divider()
                .overlay(ink.opacity(0.07))

            if let completedAt = parkingSpot.completedAt {
                let durationText = parkingDuration(
                    from: parkingSpot.parkedAt,
                    to: completedAt
                )

                HStack(spacing: 10) {
                    historyInfo(
                        icon: "clock",
                        title: "Duration",
                        value: durationText
                    )

                    historyInfo(
                        icon: "arrow.uturn.backward",
                        title: "Returned",
                        value: completedAt.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )
                }
            }

            if !parkingSpot.note.isEmpty {
                historyDetail(
                    icon: "mappin.and.ellipse",
                    title: "Spot details",
                    value: parkingSpot.note,
                    accent: parkedGreen,
                    background: softGreen
                )
            }

            if let expirationDate = parkingSpot.expirationDate {
                historyDetail(
                    icon: "timer",
                    title: "Parking expired at",
                    value: expirationDate.formatted(
                        date: .omitted,
                        time: .shortened
                    ),
                    accent: warmOrange,
                    background: Color(
                        red: 0.98,
                        green: 0.92,
                        blue: 0.82
                    )
                )
            }

            if let imageData = parkingSpot.photoData,
               let uiImage = UIImage(data: imageData) {

                VStack(alignment: .leading, spacing: 10) {
                    Text("Parking photo")
                        .font(.system(size: 13))
                        .foregroundStyle(ink.opacity(0.5))

                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 18,
                                style: .continuous
                            )
                        )
                }
            }

            HStack(spacing: 5) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 10))

                Text("Swipe to delete")
                    .font(.system(size: 11))
            }
            .foregroundStyle(ink.opacity(0.32))
            .frame(
                maxWidth: .infinity,
                alignment: .trailing
            )
        }
        .padding(18)
        .background(Color.white.opacity(0.78))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                ink.opacity(0.05),
                lineWidth: 1
            )
        }
    }

    // MARK: - History Info

    private func historyInfo(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(parkedGreen)
                .frame(width: 34, height: 34)
                .background(softGreen)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(ink.opacity(0.48))

                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ink)
            }

            Spacer(minLength: 0)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - History Detail

    private func historyDetail(
        icon: String,
        title: String,
        value: String,
        accent: Color,
        background: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 34, height: 34)
                .background(background)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(ink.opacity(0.48))

                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ink)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer(minLength: 0)
        }
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
