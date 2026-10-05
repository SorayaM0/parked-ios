import SwiftUI
import PhotosUI

struct SaveParkingView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var hasTimeLimit = false
    @State private var expirationDate = Date().addingTimeInterval(3600)
    @State private var note = ""

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    var onSave: (Date?, String, Data?) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {

                        headerCard

                        timerCard

                        detailsCard

                        photoCard

                        saveButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Save Parking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, newPhoto in
                loadPhoto(newPhoto)
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.12))
                    .frame(width: 50, height: 50)

                Image(systemName: "car.fill")
                    .foregroundStyle(.blue)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Save your parking spot")
                    .font(.headline)

                Text("Add any details that will help you find your car later.")
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
    }

    // MARK: - Timer

    private var timerCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Parking Timer")
                        .font(.headline)

                    Text("Get reminded before your parking expires.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $hasTimeLimit)
                    .labelsHidden()
            }
            .padding(16)

            if hasTimeLimit {
                Divider()
                    .padding(.leading, 54)

                HStack {
                    Text("Expires")
                        .font(.subheadline)

                    Spacer()

                    DatePicker(
                        "",
                        selection: $expirationDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                }
                .padding(16)
            }
        }
        .background(.background)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }

    // MARK: - Details

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                "Parking Details",
                systemImage: "mappin.and.ellipse"
            )
            .font(.headline)

            TextField(
                "Level 3, Spot 214, near elevator...",
                text: $note,
                axis: .vertical
            )
            .lineLimit(2...4)
            .padding(12)
            .background(
                Color(.secondarySystemGroupedBackground)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12,
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

    // MARK: - Photo

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(
                "Parking Photo",
                systemImage: "camera.fill"
            )
            .font(.headline)

            Text(
                "Save a photo of your level, spot number, or a nearby landmark."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            if let imageData = photoData,
               let uiImage = UIImage(data: imageData) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 190)
                    .clipped()
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                    )

                HStack(spacing: 12) {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        Label(
                            "Change",
                            systemImage: "photo"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        selectedPhoto = nil
                        photoData = nil
                    } label: {
                        Label(
                            "Remove",
                            systemImage: "trash"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

            } else {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images
                ) {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)

                        Text("Add Parking Photo")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .background(
                    Color.blue.opacity(0.07)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )
            }
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

    // MARK: - Save

    private var saveButton: some View {
        Button {
            onSave(
                hasTimeLimit ? expirationDate : nil,
                note,
                photoData
            )

            dismiss()
        } label: {
            Label(
                "Save Parking Spot",
                systemImage: "car.fill"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.top, 4)
    }

    // MARK: - Photo Loading

    private func loadPhoto(
        _ photo: PhotosPickerItem?
    ) {
        guard let photo else {
            return
        }

        Task {
            do {
                let data = try await photo.loadTransferable(
                    type: Data.self
                )

                await MainActor.run {
                    photoData = data
                }
            } catch {
                print(
                    "Failed to load parking photo: \(error)"
                )
            }
        }
    }
}

#Preview {
    SaveParkingView { expirationDate, note, photoData in
        print(expirationDate as Any)
        print(note)
        print(photoData as Any)
    }
}
