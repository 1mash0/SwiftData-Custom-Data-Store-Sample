import Foundation

struct NetworkError: Error {
    var error: URLError
}

struct ServerError: Error {
    var response: HTTPURLResponse
}

enum APIClient {
    static func fetch<T: Decodable>() async throws -> [T] {
        do {
            let (data, response) = try await URLSession.shared.data(from: .init(string: "http://localhost:8080/items")!)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                preconditionFailure()
            }
            
            guard 200 ..< 300 ~= httpResponse.statusCode else {
                throw ServerError(response: httpResponse)
            }
            
            let decoder: JSONDecoder = .init()
            decoder.dateDecodingStrategy = .iso8601
            
            let items = try decoder.decode([T].self, from: data)
            return items
        } catch let error as URLError {
            switch error.code {
                case .networkConnectionLost, .notConnectedToInternet, .cannotFindHost:
                    throw NetworkError(error: error)
                case .cancelled:
                    throw CancellationError()
                default:
                    throw error
            }
        }
    }
    
    static func register<T: Encodable>(_ items: [T]) async throws {
        do {
            let encoder: JSONEncoder = .init()
            encoder.dateEncodingStrategy = .iso8601
            let httpBody = try encoder.encode(items)
            
            var request: URLRequest = .init(url: .init(string: "http://localhost:8080/items")!)
            request.httpMethod = "POST"
            request.httpBody = httpBody
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                preconditionFailure()
            }
            
            guard 200 ..< 300 ~= httpResponse.statusCode else {
                throw ServerError(response: httpResponse)
            }
        } catch let error as URLError {
            switch error.code {
                case .networkConnectionLost, .notConnectedToInternet, .cannotFindHost:
                    throw NetworkError(error: error)
                case .cancelled:
                    throw CancellationError()
                default:
                    throw error
            }
        }
    }
    
    static func delete<T: Encodable>(_ items: [T]) async throws {
        do {
            let encoder: JSONEncoder = .init()
            encoder.dateEncodingStrategy = .iso8601
            let httpBody = try encoder.encode(items)
            
            var request: URLRequest = .init(url: .init(string: "http://localhost:8080/items")!)
            request.httpMethod = "PATCH"
            request.httpBody = httpBody
            request.addValue("application.json", forHTTPHeaderField: "Content-Type")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                preconditionFailure()
            }
            
            guard 200 ..< 300 ~= httpResponse.statusCode else {
                throw ServerError(response: httpResponse)
            }
        } catch let error as URLError {
            switch error.code {
                case .networkConnectionLost, .notConnectedToInternet, .cannotFindHost:
                    throw NetworkError(error: error)
                case .cancelled:
                    throw CancellationError()
                default:
                    throw error
            }
        }
    }
}
