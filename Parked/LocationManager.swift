import Foundation
import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus
    var locationError: String?
    var isRequestingLocation = false

    override init() {
        authorizationStatus = manager.authorizationStatus

        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() {
        locationError = nil
        manager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() {
        locationError = nil
        isRequestingLocation = true
         #if DEBUG && targetEnvironment(simulator)
            useSimulatorTestLocation()
              #else
              manager.requestLocation()
                #endif
    }

    private func useSimulatorTestLocation() {
        let testLocation = CLLocation(
            latitude: 40.7128,
            longitude: -74.0060
        )

        currentLocation = testLocation
        locationError = nil
        isRequestingLocation = false

        print(
            "Simulator test location: \(testLocation.coordinate.latitude), \(testLocation.coordinate.longitude)"
        )
    }

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {

        case .authorizedWhenInUse, .authorizedAlways:
            requestCurrentLocation()

        case .denied:
            isRequestingLocation = false
            locationError = "Location permission was denied."

        case .restricted:
            isRequestingLocation = false
            locationError = "Location access is restricted."

        case .notDetermined:
            break

        @unknown default:
            isRequestingLocation = false
            locationError = "Location access is unavailable."
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else {
            isRequestingLocation = false
            locationError = "Your location could not be determined."
            return
        }

        currentLocation = location
        locationError = nil
        isRequestingLocation = false

        print(
            "Location received: \(location.coordinate.latitude), \(location.coordinate.longitude)"
        )
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        isRequestingLocation = false

        if let coreLocationError = error as? CLError,
           coreLocationError.code == .locationUnknown {

            locationError =
                "Your location is temporarily unavailable. Please try again."

            print(
                "Location temporarily unavailable: \(error.localizedDescription)"
            )

            return
        }

        locationError = error.localizedDescription

        print(
            "Location error: \(error.localizedDescription)"
        )
    }
}
