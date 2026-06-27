import Foundation

struct GoogleMapsCoordinate: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let sourceURL: String
}

// Parses full Google Maps URLs to extract coordinates.
// Short links (maps.app.goo.gl) are NOT resolved — they are stored as-is.
enum GoogleMapsURLParser {

    static func parse(_ rawURL: String) -> GoogleMapsCoordinate? {
        let trimmed = rawURL.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Reject un-parseable short links (do not resolve via network)
        if trimmed.contains("maps.app.goo.gl") || trimmed.contains("goo.gl") {
            return nil
        }

        guard let url = URL(string: trimmed),
              let host = url.host,
              (host.contains("google.com") || host.contains("maps.google.com")) else {
            return nil
        }

        // Pattern 1: ?q=lat,lon or ?q=lat%2Clon
        if let coord = extractFromQParam(url) { return coord }

        // Pattern 2: /@lat,lon,zoom or /place/name/@lat,lon,zoom
        if let coord = extractFromAtSign(trimmed) { return coord }

        return nil
    }

    // MARK: - Private

    private static func extractFromQParam(_ url: URL) -> GoogleMapsCoordinate? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let q = components.queryItems?.first(where: { $0.name == "q" })?.value else {
            return nil
        }
        return parseLatLon(from: q, sourceURL: url.absoluteString)
    }

    private static func extractFromAtSign(_ rawURL: String) -> GoogleMapsCoordinate? {
        guard let atRange = rawURL.range(of: "/@") else { return nil }
        let afterAt = String(rawURL[atRange.upperBound...])
        // Take up to the next "/"
        let segment = afterAt.components(separatedBy: "/").first ?? afterAt
        return parseLatLon(from: segment, sourceURL: rawURL)
    }

    private static func parseLatLon(from text: String, sourceURL: String) -> GoogleMapsCoordinate? {
        // Accept "lat,lon" or "lat,lon,zoom" (comma or space separated)
        let parts = text
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: CharacterSet(charactersIn: ", "))
            .filter { !$0.isEmpty }

        guard parts.count >= 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1]),
              (-90...90).contains(lat),
              (-180...180).contains(lon) else {
            return nil
        }

        return GoogleMapsCoordinate(latitude: lat, longitude: lon, sourceURL: sourceURL)
    }

    // Generates a shareable Google Maps link from coordinates.
    // Does not require an API key.
    static func generateURL(latitude: Double, longitude: Double) -> String {
        String(format: "https://www.google.com/maps?q=%.6f,%.6f", latitude, longitude)
    }
}
