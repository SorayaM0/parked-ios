import SwiftUI
import MapKit
import SwiftData
import CoreLocation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ParkingSpot.parkedAt, order: .reverse)
    private var parkingSpots: [ParkingSpot]

    @State private var locationManager = LocationManager()
    @State private var showingSaveParking = false
    @State private var showingFoundCarConfirmation = false

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

    private var activeParkingSpot: ParkingSpot? {
        parkingSpots.first { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBackground
                    .ignoresSafeArea()

                if let parkingSpot = activeParkingSpot {
                    activeParkingView(parkingSpot)
                } else {
                    emptyParkingView
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(parkedGreen)

                        Text("Parked")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(ink)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ParkingHistoryView()
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(ink)
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.72))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Parking History")
                }
            }
            .toolbarBackground(pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingSaveParking) {
                SaveParkingView { expirationDate, note, photoData in
                    saveParkingSpot(
                        expirationDate: expirationDate,
                        note: note,
                        photoData: photoData
                    )
                }
            }
            .confirmationDialog(
                "Did you find your car?",
                isPresented: $showingFoundCarConfirmation,
                titleVisibility: .visible
            ) {
                Button("Yes, End Parking") {
                    endParkingSession()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "This parking session will be saved to your history."
                )
            }
            .onAppear {
                NotificationManager.shared.requestPermission()
            }
        }
        .tint(parkedGreen)
    }

    // MARK: - Empty State

    private var emptyParkingView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 24) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 24,
                        style: .continuous
                    )
                    .fill(ink)
                    .frame(width: 88, height: 88)

                    Image(systemName: "car.fill")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(pageBackground)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Never forget where you parked.")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(
                        "Save your car's location, remember the details, and find your way back when you're ready."
                    )
                    .font(.system(size: 17))
                    .foregroundStyle(ink.opacity(0.62))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            Button {
                prepareToSaveParking()
            } label: {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Park Here")
                            .font(.system(size: 17, weight: .semibold))

                        Text("Save my current location")
                            .font(.system(size: 13))
                            .opacity(0.76)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 42, height: 42)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Circle())
                }
                .foregroundStyle(.white)
                .padding(.leading, 20)
                .padding(.trailing, 12)
                .padding(.vertical, 12)
                .background(parkedGreen)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 22)
    }

    // MARK: - Active Parking

    private func activeParkingView(
        _ parkingSpot: ParkingSpot
    ) -> some View {
        let coordinate = CLLocationCoordinate2D(
            latitude: parkingSpot.latitude,
            longitude: parkingSpot.longitude
        )

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Hero

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(parkedGreen)
                            .frame(width: 8, height: 8)

                        Text("Car is parked")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(parkedGreen)
                    }

                    Text("Your car is parked.")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(ink)

                    Text(
                        "Saved at \(parkingSpot.parkedAt.formatted(date: .omitted, time: .shortened))"
                    )
                    .font(.system(size: 15))
                    .foregroundStyle(ink.opacity(0.58))
                }
                .padding(.top, 8)

                // MARK: Map

                ZStack(alignment: .topLeading) {
                    Map(
                        initialPosition: .region(
                            MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(
                                    latitudeDelta: 0.005,
                                    longitudeDelta: 0.005
                                )
                            )
                        )
                    ) {
                        Marker(
                            "My Car",
                            systemImage: "car.fill",
                            coordinate: coordinate
                        )
                        .tint(parkedGreen)
                    }
                    .frame(height: 300)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 26,
                            style: .continuous
                        )
                    )

                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 11, weight: .semibold))

                        Text("Your car")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ink.opacity(0.88))
                    .clipShape(Capsule())
                    .padding(14)
                }

                // MARK: Parking Time

                if let expirationDate = parkingSpot.expirationDate {
                    parkingTimerCard(expirationDate)
                }

                // MARK: Details

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("Spot details")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(ink)

                        Spacer()

                        Button {
                            prepareToSaveParking()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))

                                Text("Edit")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundStyle(parkedGreen)
                        }
                        .buttonStyle(.plain)
                    }

                    detailItem(
                        icon: "clock",
                        label: "Parked",
                        value: parkingSpot.parkedAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )

                    if !parkingSpot.note.isEmpty {
                        Divider()
                            .overlay(ink.opacity(0.08))

                        detailItem(
                            icon: "mappin",
                            label: "Parking note",
                            value: parkingSpot.note
                        )
                    }
                }
                .padding(20)
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
                    .stroke(ink.opacity(0.06), lineWidth: 1)
                }

                // MARK: Photo

                if let imageData = parkingSpot.photoData,
                   let uiImage = UIImage(data: imageData) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "photo")
                                .foregroundStyle(parkedGreen)

                            Text("Parking photo")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(ink)
                        }

                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipped()
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 18,
                                    style: .continuous
                                )
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
                }

                // MARK: Directions

                Button {
                    openDirections(to: parkingSpot)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Directions to My Car")
                                .font(.system(size: 17, weight: .semibold))

                            Text("Open walking directions")
                                .font(.system(size: 13))
                                .opacity(0.7)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                    .padding(.trailing, 6)
                    .background(ink)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 22,
                            style: .continuous
                        )
                    )
                }
                .buttonStyle(.plain)

                // MARK: Found Car

                Button {
                    showingFoundCarConfirmation = true
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))

                        Text("I'm Back at My Car")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(parkedGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(softGreen.opacity(0.75))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                    )
                }
                .buttonStyle(.plain)

                Text("Parked")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ink.opacity(0.28))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
                    .padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Timer Card

    private func parkingTimerCard(
        _ expirationDate: Date
    ) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let remaining = expirationDate.timeIntervalSince(context.date)
            let isExpired = remaining <= 0

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(
                        isExpired
                        ? "Parking expired"
                        : "Time remaining"
                    )
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        isExpired
                        ? Color.red.opacity(0.8)
                        : warmOrange
                    )

                    Text(
                        isExpired
                        ? "Expired"
                        : remainingTimeString(remaining)
                    )
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(ink)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            isExpired
                            ? .red
                            : warmOrange
                        )

                    Text(
                        expirationDate.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ink.opacity(0.6))
                }
            }
            .padding(22)
            .background(
                isExpired
                ? Color.red.opacity(0.07)
                : Color(
                    red: 0.98,
                    green: 0.92,
                    blue: 0.82
                )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
            )
        }
    }

    // MARK: - Detail Item

    private func detailItem(
        icon: String,
        label: String,
        value: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(parkedGreen)
                .frame(width: 36, height: 36)
                .background(softGreen)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 11,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(ink.opacity(0.5))

                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Timer Formatting

    private func remainingTimeString(
        _ interval: TimeInterval
    ) -> String {
        let totalMinutes = max(Int(interval / 60), 0)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }

    // MARK: - Directions

    private func openDirections(
        to parkingSpot: ParkingSpot
    ) {
        let location = CLLocation(
            latitude: parkingSpot.latitude,
            longitude: parkingSpot.longitude
        )

        let destination = MKMapItem(
            location: location,
            address: nil
        )

        destination.name = "My Parked Car"

        destination.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey:
                    MKLaunchOptionsDirectionsModeWalking
            ]
        )
    }

    // MARK: - Location

    private func prepareToSaveParking() {
        switch locationManager.authorizationStatus {

        case .notDetermined:
            locationManager.requestLocationPermission()

        case .authorizedWhenInUse, .authorizedAlways:
            if locationManager.currentLocation != nil {
                showingSaveParking = true
            } else {
                locationManager.requestCurrentLocation()

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 1
                ) {
                    if locationManager.currentLocation != nil {
                        showingSaveParking = true
                    }
                }
            }

        case .denied, .restricted:
            print("Location permission is unavailable.")

        @unknown default:
            break
        }
    }

    // MARK: - Save Parking

    private func saveParkingSpot(
        expirationDate: Date?,
        note: String,
        photoData: Data?
    ) {
        guard let location = locationManager.currentLocation else {
            return
        }

        if let existingSpot = activeParkingSpot {
            existingSpot.latitude =
                location.coordinate.latitude

            existingSpot.longitude =
                location.coordinate.longitude

            existingSpot.parkedAt = Date()
            existingSpot.note = note
            existingSpot.expirationDate = expirationDate
            existingSpot.photoData = photoData

        } else {
            let parkingSpot = ParkingSpot(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                parkedAt: Date(),
                note: note,
                expirationDate: expirationDate,
                isActive: true,
                photoData: photoData
            )

            modelContext.insert(parkingSpot)
        }

        do {
            try modelContext.save()

            NotificationManager.shared.cancelParkingReminder()

            if let expirationDate {
                NotificationManager.shared.scheduleParkingReminder(
                    for: expirationDate
                )
            }

            print("Parking spot saved successfully.")

        } catch {
            print(
                "Failed to save parking spot: \(error)"
            )
        }
    }

    // MARK: - End Parking

    private func endParkingSession() {
        guard let parkingSpot = activeParkingSpot else {
            return
        }

        parkingSpot.isActive = false
        parkingSpot.completedAt = Date()

        NotificationManager.shared.cancelParkingReminder()

        do {
            try modelContext.save()
            print("Parking session completed.")
        } catch {
            print(
                "Failed to complete parking session: \(error)"
            )
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: ParkingSpot.self,
            inMemory: true
        )
}
