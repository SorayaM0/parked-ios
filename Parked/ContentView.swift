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

    private var activeParkingSpot: ParkingSpot? {
        parkingSpots.first { $0.isActive }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if let parkingSpot = activeParkingSpot {
                    activeParkingView(parkingSpot)
                } else {
                    emptyParkingView
                }
            }
            .navigationTitle("Parked")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ParkingHistoryView()
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .accessibilityLabel("Parking History")
                }
            }
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
    }

    // MARK: - Empty State

    private var emptyParkingView: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.blue.opacity(0.12))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(.blue.opacity(0.08))
                    .frame(width: 105, height: 105)

                Image(systemName: "car.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 10) {
                Text("Where did you park?")
                    .font(.title)
                    .fontWeight(.bold)

                Text(
                    "Save your car's location, set a parking reminder, and find your way back when you're ready."
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }
            .padding(.top, 28)

            Spacer()

            Button {
                prepareToSaveParking()
            } label: {
                Label(
                    "Save My Parking Spot",
                    systemImage: "location.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(20)
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
            VStack(spacing: 18) {

                // Status

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.green.opacity(0.14))
                            .frame(width: 44, height: 44)

                        Image(systemName: "checkmark")
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Car location saved")
                            .font(.headline)

                        Text("We'll remember where you parked.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(.background)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )

                // Map

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
                }
                .frame(height: 280)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                    .stroke(
                        Color.primary.opacity(0.06),
                        lineWidth: 1
                    )
                }

                // Parking information

                VStack(spacing: 0) {
                    informationRow(
                        icon: "clock.fill",
                        title: "Parked",
                        value: parkingSpot.parkedAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )

                    if let expirationDate = parkingSpot.expirationDate {
                        Divider()
                            .padding(.leading, 52)

                        informationRow(
                            icon: "timer",
                            title: "Parking expires",
                            value: expirationDate.formatted(
                                date: .omitted,
                                time: .shortened
                            ),
                            iconColor: .orange
                        )
                    }

                    if !parkingSpot.note.isEmpty {
                        Divider()
                            .padding(.leading, 52)

                        informationRow(
                            icon: "mappin.and.ellipse",
                            title: "Parking details",
                            value: parkingSpot.note
                        )
                    }
                }
                .background(.background)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 20,
                        style: .continuous
                    )
                )

                // Photo

                if let imageData = parkingSpot.photoData,
                   let uiImage = UIImage(data: imageData) {

                    VStack(alignment: .leading, spacing: 12) {
                        Label(
                            "Parking Photo",
                            systemImage: "photo.fill"
                        )
                        .font(.headline)

                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 210)
                            .clipped()
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 16,
                                    style: .continuous
                                )
                            )
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

                // Main action

                Button {
                    openDirections(to: parkingSpot)
                } label: {
                    Label(
                        "Directions to My Car",
                        systemImage: "figure.walk"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                // Secondary actions

                HStack(spacing: 12) {
                    Button {
                        prepareToSaveParking()
                    } label: {
                        Label(
                            "Update",
                            systemImage: "pencil"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        showingFoundCarConfirmation = true
                    } label: {
                        Label(
                            "Found Car",
                            systemImage: "checkmark.circle"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Information Row

    private func informationRow(
        icon: String,
        title: String,
        value: String,
        iconColor: Color = .blue
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(16)
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
