import Foundation
import SwiftData

@Model
final class ParkingSpot {

    var latitude: Double
    var longitude: Double
    var parkedAt: Date
    var note: String
    var expirationDate: Date?

    var isActive: Bool
    var completedAt: Date?

    @Attribute(.externalStorage)
    var photoData: Data?

    init(
        latitude: Double,
        longitude: Double,
        parkedAt: Date = Date(),
        note: String = "",
        expirationDate: Date? = nil,
        isActive: Bool = true,
        completedAt: Date? = nil,
        photoData: Data? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.parkedAt = parkedAt
        self.note = note
        self.expirationDate = expirationDate
        self.isActive = isActive
        self.completedAt = completedAt
        self.photoData = photoData
    }
}
