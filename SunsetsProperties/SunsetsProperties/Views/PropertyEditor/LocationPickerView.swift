import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var detectedAddress: String?
    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var position: MapCameraPosition
    @State private var isReverseGeocoding: Bool = false

    // Guatemala City default center
    private static let guatemalaCity = CLLocationCoordinate2D(latitude: 14.6349, longitude: -90.5069)

    let initialLatitude: Double?
    let initialLongitude: Double?
    let onConfirm: (Double, Double, String?) -> Void

    init(latitude: Double?, longitude: Double?, onConfirm: @escaping (Double, Double, String?) -> Void) {
        self.initialLatitude = latitude
        self.initialLongitude = longitude
        self.onConfirm = onConfirm

        let center: CLLocationCoordinate2D
        if let lat = latitude, let lon = longitude {
            center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            center = Self.guatemalaCity
        }
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        _position = State(initialValue: .region(MKCoordinateRegion(center: center, span: span)))

        if let lat = latitude, let lon = longitude {
            _selectedCoordinate = State(initialValue: CLLocationCoordinate2D(latitude: lat, longitude: lon))
        } else {
            _selectedCoordinate = State(initialValue: nil)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBarSection
                mapSection
                if selectedCoordinate != nil {
                    coordinateFooter
                }
            }
            .navigationTitle("Seleccionar ubicación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Confirmar") {
                        if let coord = selectedCoordinate {
                            onConfirm(coord.latitude, coord.longitude, detectedAddress)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedCoordinate == nil)
                }
            }
        }
    }

    // MARK: - Sections

    private var searchBarSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Buscar dirección…", text: $searchText)
                    .autocorrectionDisabled()
                    .onSubmit { Task { await performSearch() } }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.vertical, 8)

            if !searchResults.isEmpty {
                Divider()
                searchResultsList
            }
        }
    }

    private var searchResultsList: some View {
        List(searchResults, id: \.self) { item in
            Button {
                selectSearchResult(item)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name ?? "")
                        .fontWeight(.medium)
                    Text([item.placemark.locality, item.placemark.country]
                        .compactMap { $0 }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .frame(maxHeight: 200)
    }

    private var mapSection: some View {
        MapReader { proxy in
            Map(position: $position) {
                if let coord = selectedCoordinate {
                    Annotation("", coordinate: coord, anchor: .bottom) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red, .white)
                    }
                }
            }
            .onTapGesture { point in
                if let coord = proxy.convert(point, from: .local) {
                    selectedCoordinate = coord
                    Task { await reverseGeocode(coord) }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var coordinateFooter: some View {
        VStack(spacing: 4) {
            if isReverseGeocoding {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Obteniendo dirección…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let address = detectedAddress {
                Text(address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            if let coord = selectedCoordinate {
                Text(String(format: "%.6f,  %.6f", coord.latitude, coord.longitude))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Actions

    private func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        // Bias towards Guatemala
        let bias = MKCoordinateRegion(
            center: Self.guatemalaCity,
            latitudinalMeters: 400_000,
            longitudinalMeters: 400_000
        )
        request.region = bias

        if let response = try? await MKLocalSearch(request: request).start() {
            searchResults = Array(response.mapItems.prefix(5))
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        guard let location = item.placemark.location else { return }
        let coord = location.coordinate
        selectedCoordinate = coord
        detectedAddress = buildAddressString(from: item.placemark)
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        position = .region(MKCoordinateRegion(center: coord, span: span))
        searchResults = []
        searchText = ""
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async {
        isReverseGeocoding = true
        defer { isReverseGeocoding = false }
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
           let first = placemarks.first {
            detectedAddress = buildAddressString(from: first)
        }
    }

    private func buildAddressString(from placemark: CLPlacemark) -> String {
        [placemark.name, placemark.thoroughfare, placemark.locality,
         placemark.administrativeArea, placemark.country]
        .compactMap { $0 }
        .joined(separator: ", ")
    }

    private func buildAddressString(from placemark: MKPlacemark) -> String {
        [placemark.name, placemark.thoroughfare, placemark.locality,
         placemark.administrativeArea, placemark.country]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}
