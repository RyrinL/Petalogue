//
//  PlantNetService.swift
//  Petalogue
//
//  Primary (network) identifier. Uploads a single flower photo to the
//  Pl@ntNet REST API and maps the response into IdentificationResults,
//  matching latin names against the bundled catalog.
//
//  API key lives in the gitignored Secrets.swift.
//

import UIKit

final class PlantNetService: FlowerIdentifying {
    private let catalog: CatalogService
    private let session: URLSession
    private let apiKey: String
    private let jpegQuality: CGFloat

    /// Pl@ntNet "all" project endpoint. Key is passed as a query item.
    private let endpoint = "https://my-api.plantnet.org/v2/identify/all"

    init(
        catalog: CatalogService = .shared,
        session: URLSession = .shared,
        apiKey: String = Secrets.plantNetAPIKey,
        jpegQuality: CGFloat = 0.85
    ) {
        self.catalog = catalog
        self.session = session
        self.apiKey = apiKey
        self.jpegQuality = jpegQuality
    }

    enum PlantNetError: LocalizedError {
        case missingAPIKey
        case imageEncodingFailed
        case badResponse(status: Int)
        case noResults

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Add your Pl@ntNet API key to Secrets.swift."
            case .imageEncodingFailed:
                return "Could not prepare the photo for upload."
            case .badResponse(let status):
                return "Pl@ntNet returned an error (HTTP \(status))."
            case .noResults:
                return "No flower could be identified in that photo."
            }
        }
    }

    func identify(_ image: UIImage) async throws -> [IdentificationResult] {
        guard !apiKey.isEmpty, apiKey != "YOUR_KEY_HERE" else {
            throw PlantNetError.missingAPIKey
        }
        guard let jpeg = image.jpegData(compressionQuality: jpegQuality) else {
            throw PlantNetError.imageEncodingFailed
        }

        var components = URLComponents(string: endpoint)!
        components.queryItems = [URLQueryItem(name: "api-key", value: apiKey)]
        guard let url = components.url else { throw PlantNetError.missingAPIKey }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = makeBody(jpeg: jpeg, boundary: boundary)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PlantNetError.badResponse(status: -1)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw PlantNetError.badResponse(status: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(PlantNetResponse.self, from: data)
        let results = decoded.results.prefix(5).map { result -> IdentificationResult in
            let latin = result.species.scientificNameWithoutAuthor
            let match = catalog.match(latinName: latin)
            return IdentificationResult(
                speciesID: match?.id ?? "",
                commonName: match?.commonName ?? result.species.commonNames.first ?? latin,
                latinName: latin,
                confidence: result.score
            )
        }

        guard !results.isEmpty else { throw PlantNetError.noResults }
        return Array(results)
    }

    // MARK: - Multipart body

    private func makeBody(jpeg: Data, boundary: String) -> Data {
        var body = Data()
        func append(_ string: String) { body.append(Data(string.utf8)) }

        // organs field — we always submit a single "flower" organ.
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"organs\"\r\n\r\n")
        append("flower\r\n")

        // image field
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"images\"; filename=\"flower.jpg\"\r\n")
        append("Content-Type: image/jpeg\r\n\r\n")
        body.append(jpeg)
        append("\r\n")

        append("--\(boundary)--\r\n")
        return body
    }
}

// MARK: - Pl@ntNet response shape

private struct PlantNetResponse: Decodable {
    let results: [Result]

    struct Result: Decodable {
        let score: Double
        let species: Species
    }

    struct Species: Decodable {
        let scientificNameWithoutAuthor: String
        let commonNames: [String]
    }
}
