//
//  File.swift
//  
//
//  Created by Oğuz Demirhan on 11.04.2022.
//

import Foundation


public enum HTTPMethod {
    case Get
    case Post
    case Put
    case Delete
    
    var type: String {
        switch self {
        case .Get:
            return "GET"
        case .Post:
            return "POST"
        case .Put:
            return "PUT"
        case .Delete:
            return "DELETE"
        }
    }
}

public protocol Endpoint {
    var baseUrl: String { get }
    var path: String { get }
    var parameters: [String: Any] { get }
    var headers: [String: String] { get}
    var method: HTTPMethod { get }
}

public extension Endpoint {
    var method: HTTPMethod { .Get }
    var headers: [String: String] { [:] }
    var parameters: [String: Any] { [:] }
    var url: String { "\(baseUrl)\(path)"}
}

public enum NetworkError: Error {
    case urlError
    case decodingError
    case responseError
    case dataError
    case parameterError
    
    var customDescription: String {
        
        switch self {
        case .urlError:
            return "There is error with url"
        case .decodingError:
            return "There is error with decoding"
        case .responseError:
            return "There is error with response code"
        case .dataError:
            return "There is error with data"
        case .parameterError:
            return "There is error with parameters"
        }
    }
}

public class NetworkService<EndpointItem: Endpoint>  {
    
    public init() {}
    
    public func fetchRequest<T: Decodable >(endpointItem: EndpointItem,_ type: T.Type, completion: @escaping(Result<T,NetworkError>) -> ()) {
        
        guard let url = URL(string: endpointItem.url ) else {
            completion(.failure(.urlError))
            return
        }
        
        var request = URLRequest(url: url)
        
        if !endpointItem.headers.isEmpty {
            request.allHTTPHeaderFields = endpointItem.headers
        }
        
        if !endpointItem.parameters.isEmpty {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: endpointItem.parameters, options: .fragmentsAllowed)
            } catch let error {
                print(error.localizedDescription)
                completion(.failure(.parameterError))
            }
        }
       
        request.httpMethod = endpointItem.method.type
        
        let task = URLSession.shared.dataTask(with: request) { data, resp, err in
            
            if err != nil {
                completion(.failure(.dataError))
                return
            }
            
            guard let httpResponse = resp as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                completion(.failure(.responseError))
                return
            }
            
            guard let data = data else {
                completion(.failure(.dataError))
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                print(jsonResponse)
            }
            
            catch {
                completion(.failure(.dataError))
            }
            
            do {
                let decoder = try JSONDecoder().decode(type, from: data)
                
                completion(.success(decoder))
            } catch {
                completion(.failure(.decodingError))
            }
            
        }
        
        task.resume()
    }
    
}
