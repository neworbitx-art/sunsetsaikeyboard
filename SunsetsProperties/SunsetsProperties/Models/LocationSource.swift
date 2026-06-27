import Foundation

enum LocationSource: String, Codable, CaseIterable, Sendable {
    case manual        // User typed the location summary by hand
    case mapPicker     // User placed a pin on the MapKit map
    case addressSearch // User selected an MKLocalSearch result
    case googleMapsURL // User pasted a Google Maps URL; coordinates extracted
}
