import Foundation
import Combine
import CoreLocation
import SwiftUI

// MARK: - City Coordinates (from TempNamaz)
struct Coordinates {
    let latitude: Double
    let longitude: Double
}

let cityCoordinates: [String: Coordinates] = [
    "Mecca": Coordinates(latitude: 21.4225, longitude: 39.8262),
    "Madinah": Coordinates(latitude: 24.5247, longitude: 39.5692),
    "London": Coordinates(latitude: 51.5074, longitude: 0.1278),
    "New York": Coordinates(latitude: 40.7128, longitude: -74.0060),
    "Karachi": Coordinates(latitude: 24.8608, longitude: 67.0104),
    "Jakarta": Coordinates(latitude: -6.2088, longitude: 106.8456),
    "Cairo": Coordinates(latitude: 30.0333, longitude: 31.2333),
    "Istanbul": Coordinates(latitude: 41.0082, longitude: 28.9784),
    "Kuala Lumpur": Coordinates(latitude: 3.1390, longitude: 101.6869),
    "Toronto": Coordinates(latitude: 43.6532, longitude: -79.3832),
    "Paris": Coordinates(latitude: 48.8566, longitude: 2.3522),
    "Dubai": Coordinates(latitude: 25.2048, longitude: 55.2708),
    "Abu Dhabi": Coordinates(latitude: 24.4539, longitude: 54.3773),
    "Riyadh": Coordinates(latitude: 24.7136, longitude: 46.6753),
    "Sydney": Coordinates(latitude: -33.8688, longitude: 151.2093),
    "Berlin": Coordinates(latitude: 52.5200, longitude: 13.4050),
    "Tokyo": Coordinates(latitude: 35.6895, longitude: 139.6917),
    "Los Angeles": Coordinates(latitude: 34.0522, longitude: -118.2437)
]

let kaabaCoordinates = Coordinates(latitude: 21.4225, longitude: 39.8262)

// MARK: - Double Extensions
private extension Double {
    var degreesToRadians: Double { return self * .pi / 180 }
    var radiansToDegrees: Double { return self * 180 / .pi }
    var normalizedAngle: Double {
        var angle = self.truncatingRemainder(dividingBy: 360)
        if angle < 0 { angle += 360 }
        return angle
    }
}

// MARK: - Haptics (from TempNamaz)
#if os(iOS)
import UIKit
class HapticManager {
    static let shared = HapticManager()
    
    func notifySuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
#else
class HapticManager {
    static let shared = HapticManager()
    func notifySuccess() {}
}
#endif

// MARK: - Qibla Location Service (TempNamaz Logic)
final class QiblaLocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    @Published var userHeading: Double = 0.0
    @Published var isCalibrated: Bool = false
    @Published var currentLocation: CLLocation?
    
    var headingAccuracy: Double {
        return locationManager.heading?.headingAccuracy ?? -1.0
    }
    
    var isAuthorizedWhenInUse: Bool {
        #if os(iOS) || os(watchOS) || os(visionOS) || os(tvOS)
        let status = locationManager.authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
        #elseif os(macOS)
        // On macOS, .authorizedWhenInUse is unavailable. Treat .authorizedAlways as authorized.
        let status = locationManager.authorizationStatus
        if #available(macOS 11.0, *) {
            return status == .authorizedAlways
        } else {
            // Fallback for older macOS SDKs where .authorized was used
            return status == .authorized
        }
        #else
        return false
        #endif
    }
    
    var hasLocationFix: Bool {
        return currentLocation != nil
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        #if os(iOS) || os(watchOS) || os(visionOS) || os(tvOS)
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
        #endif
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.currentLocation = location
        }
        if let heading = manager.heading {
            self.isCalibrated = heading.headingAccuracy >= 0
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.trueHeading >= 0 {
            userHeading = newHeading.trueHeading.normalizedAngle
        } else {
            userHeading = newHeading.magneticHeading.normalizedAngle
        }
        
        isCalibrated = newHeading.headingAccuracy >= 0
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return manager.heading?.headingAccuracy ?? -1 < 0
    }
}

// MARK: - Qibla View Model (TempNamaz Logic + Wasl Properties)
final class QiblaViewModel: ObservableObject {
    
    @Published var userHeading: Double = 0.0
    @Published var qiblaAngle: Double = 0.0
    @Published var currentCity: String?
    @Published var isAligned: Bool = false
    @Published var isCalibrated: Bool = false
    @Published var totalRotation: Double = 0.0
    
    // For Wasl UI compatibility
    @Published var statusMessage: String = "Initializing..."
    @Published var locationStatus: String = "Location Not Determined"
    
    private var locationService = QiblaLocationService()
    private var headingCancellable: AnyCancellable?
    private var calibrationCancellable: AnyCancellable?
    private var locationCancellable: AnyCancellable?
    
    init(city: String = "Dubai") {
        self.currentCity = city
        self.qiblaAngle = calculateQiblaBearing(city: city)
        
        headingCancellable = locationService.$userHeading
            .sink { [weak self] newHeading in
                guard let self = self else { return }
                
                var difference = newHeading - self.userHeading
                if difference > 180 { difference -= 360 }
                else if difference < -180 { difference += 360 }
                
                self.totalRotation += difference
                self.userHeading = newHeading
                self.checkAlignment()
            }
        
        calibrationCancellable = locationService.$isCalibrated
            .sink { [weak self] isCalibrated in
                self?.isCalibrated = isCalibrated
                self?.updateStatusMessage()
            }
        
        locationCancellable = locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] newLocation in
                guard let city = self?.currentCity else { return }
                self?.qiblaAngle = self?.calculateQiblaBearing(city: city) ?? 0.0
                self?.locationStatus = String(format: "Lat: %.3f, Lon: %.3f",
                                              newLocation.coordinate.latitude,
                                              newLocation.coordinate.longitude)
            }
    }
    
    var locationStatusForUI: String {
        return "Accurate Gyroscope"
    }
    
    private func updateStatusMessage() {
        let headingAccurate = locationService.headingAccuracy >= 0.0
        let isAuthorized = locationService.isAuthorizedWhenInUse
        
        if !isAuthorized || !locationService.hasLocationFix {
            statusMessage = "Waiting for Location Data.\nLocation Services must be enabled."
            return
        }
        
        if !isCalibrated {
            if !headingAccurate {
                statusMessage = "Calibrate the compass by waving the device in a figure eight motion."
            } else {
                statusMessage = "Acquiring accurate GPS location..."
            }
            return
        }
        
        statusMessage = isAligned ? "Qibla Aligned. Keep steady." : "Align the top edge with the Qibla Indicator."
    }
    
    private func calculateQiblaBearing(city: String) -> Double {
        guard let currentLocation = cityCoordinates[city] else { return 0 }
        
        let lat1 = currentLocation.latitude.degreesToRadians
        let lon1 = currentLocation.longitude.degreesToRadians
        let lat2 = kaabaCoordinates.latitude.degreesToRadians
        let lon2 = kaabaCoordinates.longitude.degreesToRadians
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        var bearing = atan2(y, x).radiansToDegrees
        if bearing < 0 { bearing += 360 }
        return bearing
    }
    
    private func checkAlignment() {
        guard isCalibrated else { return }
        
        var angleDifference = qiblaAngle - userHeading
        
        while angleDifference > 180 { angleDifference -= 360 }
        while angleDifference < -180 { angleDifference += 360 }
        
        let isClose = abs(angleDifference) < 5.0
        
        if isClose {
            if !self.isAligned {
                HapticManager.shared.notifySuccess()
                self.isAligned = true
            }
        } else {
            self.isAligned = false
        }
        
        updateStatusMessage()
    }
    
    func updateCity(_ city: String) {
        self.currentCity = city
        self.qiblaAngle = calculateQiblaBearing(city: city)
    }
}

