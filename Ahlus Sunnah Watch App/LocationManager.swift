import CoreLocation
import Combine
import SwiftUI

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: Published Properties
    
    /// User's current latitude (defaults to 30.0 for initial calculation until location is found)
    @Published var latitude: Double = 30.0
    
    /// User's current longitude (defaults to 31.0 for initial calculation until location is found)
    @Published var longitude: Double = 31.0
    
    /// The user-friendly name of the current location (e.g., "Dubai, UAE")
    @Published var locationName: String = "Detecting Location..."
    
    /// The manager object
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        // Use a balanced accuracy for power efficiency in a prayer app
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        checkLocationAuthorization()
    }
    
    // MARK: Authorization and Updates
    
    func checkLocationAuthorization() {
        // Request a one-time location update, or request authorization if needed
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch self.locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                // Start getting location if authorized
                self.locationManager.requestLocation()
                
            case .notDetermined:
                // This triggers the user prompt
                self.locationManager.requestWhenInUseAuthorization()
                
            case .restricted, .denied:
                // Update status if denied
                self.locationName = "Location Access Denied"
                
            @unknown default:
                break
            }
        }
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // When permission status changes, re-check
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        // Only update if the new location is significantly different
        if abs(self.latitude - location.coordinate.latitude) > 0.01 || abs(self.longitude - location.coordinate.longitude) > 0.01 {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
            
            // Reverse Geocode to get a user-friendly name
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
                guard let self = self else { return }
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? ""
                    let country = placemark.isoCountryCode ?? ""
                    
                    DispatchQueue.main.async {
                        if !city.isEmpty && !country.isEmpty {
                            self.locationName = "\(city), \(country)"
                        } else if !city.isEmpty {
                            self.locationName = city
                        } else if !country.isEmpty {
                            self.locationName = country
                        } else {
                            self.locationName = "Location Found"
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.locationName = "Location Found (\(String(format: "%.2f", self.latitude))°)"
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Failed: \(error.localizedDescription)")
        self.locationName = "Location Error"
    }
}
