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

    var body: some View {
        NavigationStack {
            ZStack {
                pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        introSection
                        timerCard
                        detailsCard
                        photoCard
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("New parking spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                    .foregroundStyle(ink.opacity(0.7))
                }
            }
            .tint(parkedGreen)
            .onChange(of: selectedPhoto) { _, newPhoto in
                loadPhoto(newPhoto)
            }
        }
    }

    // MARK: - Intro

    private var introSection: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(ink)
                .frame(width: 58, height: 58)

                Image(systemName: "car.fill")
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(pageBackground)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Remember this spot")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(ink)

                Text(
                    "Add anything that will make your car easier to find later."
                )
                .font(.system(size: 14))
                .foregroundStyle(ink.opacity(0.58))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Timer

    private var timerCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(warmOrange)
                    .frame(width: 38, height: 38)
                    .background(
                        Color(
                            red: 0.98,
                            green: 0.92,
                            blue: 0.82
                        )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Parking timer")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(ink)

                    Text("Remind me before my parking expires")
                        .font(.system(size: 13))
                        .foregroundStyle(ink.opacity(0.52))
                }

                Spacer()

                Toggle("", isOn: $hasTimeLimit)
                    .labelsHidden()
                    .tint(parkedGreen)
            }
            .padding(18)

            if hasTimeLimit {
                Divider()
                    .overlay(ink.opacity(0.08))
                    .padding(.horizontal, 18)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Parking expires")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ink.opacity(0.55))

                    DatePicker(
                        "Expiration",
                        selection: $expirationDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(18)
            }
        }
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
            .stroke(ink.opacity(0.05), lineWidth: 1)
        }
    }

    // MARK: - Details

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(parkedGreen)
                    .frame(width: 36, height: 36)
                    .background(softGreen)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 11,
                            style: .continuous
                        )
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("Spot details")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(ink)

                    Text("Optional")
                        .font(.system(size: 12))
                        .foregroundStyle(ink.opacity(0.45))
                }
            }

            TextField(
                "Level, row, spot number, nearby landmark...",
                text: $note,
                axis: .vertical
            )
            .font(.system(size: 15))
            .lineLimit(3...5)
            .padding(14)
            .background(pageBackground.opacity(0.75))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .stroke(ink.opacity(0.06), lineWidth: 1)
            }
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
            .stroke(ink.opacity(0.05), lineWidth: 1)
        }
    }

    // MARK: - Photo

    private var photoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "camera.fill")
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

                VStack(alignment: .leading, spacing: 3) {
                    Text("Parking photo")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(ink)

                    Text("Optional")
                        .font(.system(size: 12))
                        .foregroundStyle(ink.opacity(0.45))
                }
            }

            Text(
                "Take a visual reminder of your level, spot number, or a nearby landmark."
            )
            .font(.system(size: 14))
            .foregroundStyle(ink.opacity(0.58))
            .lineSpacing(2)

            if let imageData = photoData,
               let uiImage = UIImage(data: imageData) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                    )

                HStack(spacing: 10) {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        HStack(spacing: 7) {
                            Image(systemName: "photo")
                            Text("Change")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(pageBackground)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14,
                                style: .continuous
                            )
                        )
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        selectedPhoto = nil
                        photoData = nil
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "trash")
                            Text("Remove")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.07))
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14,
                                style: .continuous
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }

            } else {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images
                ) {
                    HStack(spacing: 14) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(parkedGreen)
                            .frame(width: 44, height: 44)
                            .background(softGreen)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Add a photo")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(ink)

                            Text("Choose from your photo library")
                                .font(.system(size: 12))
                                .foregroundStyle(ink.opacity(0.5))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ink.opacity(0.35))
                    }
                    .padding(14)
                    .background(pageBackground.opacity(0.75))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 17,
                            style: .continuous
                        )
                    )
                }
                .buttonStyle(.plain)
            }
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
            .stroke(ink.opacity(0.05), lineWidth: 1)
        }
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
            HStack(spacing: 12) {
                Image(systemName: "car.fill")
                    .font(.system(size: 15, weight: .semibold))

                Text("Save Parking Spot")
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 17)
            .background(parkedGreen)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
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
