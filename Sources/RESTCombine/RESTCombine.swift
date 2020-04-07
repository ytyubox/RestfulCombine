import Foundation
import Combine

extension URLSession {
	func datataskPublisher<Body,Success,Failure>  (
		_ endpoint: APIEndPoint<Body,Success,Failure>
	) -> URLSession.DataTaskPublisher
		where Body: Encoded & Queryed, Success: Decodable, Failure: Decodable {
		let request = endpoint.request
		return  dataTaskPublisher(for: request)
	}
}
