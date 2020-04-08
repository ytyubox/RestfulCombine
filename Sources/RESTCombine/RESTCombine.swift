import Foundation
import Combine
public typealias SinkBags = Set<AnyCancellable>
public
extension URLSession {
	func dataTaskPublisher<Body,Success,Failure>  (
		for endpoint: APIEndPoint<Body,Success,Failure>
	) -> URLSession.DataTaskPublisher
		where Body: Encoded & Queryed, Success: Decodable, Failure: Decodable {
			let request = endpoint.request
			return  dataTaskPublisher(for: request)
	}
}

public
extension Publisher {
	func decode<Success,Failure,Decoder>(
		for successType: Success.Type,
		fail failureType: Failure.Type,
		decoder: Decoder
	) -> AnyPublisher<Success, Error>
		where
		Success: Decodable,
		Failure: Decodable & Error,
		Decoder: TopLevelDecoder,
		Self.Output == Decoder.Input {
			tryMap { (data)  in
				var sError: DecodingError?
				do {
					return try decoder.decode(Success.self, from:data)
				} catch {
					sError = (error as! DecodingError)
				}
				if let f = try? decoder.decode(Failure.self, from: data) {
					throw f
				}
				else {
					throw sError!
				}
			}
			.eraseToAnyPublisher()
	}
	
	func twoDecode<Success,Failure,Decoder>(
		_ successType: Success.Type,
		_ failureType: Failure.Type,
		decoder: Decoder
	) -> AnyPublisher<Result<Success, Failure>, Error>
		where
		Success: Decodable,
		Failure: Decodable & Error,
		Decoder: TopLevelDecoder,
		Self.Output == Decoder.Input {
			tryMap { (o)  in
				return try decoder.decode(Result<Success,Failure>.self, from:o)
			}
			.eraseToAnyPublisher()
	}
	func twoDecode<Success,Failure,Decoder>(
		successType: Success.Type,
		successDecoder: Decoder,
		failureType: Failure.Type,
		failureDecoder: Decoder
	) -> AnyPublisher<Result<Success, Failure>, Error>
		where
		Success: Decodable,
		Failure: Decodable & Error,
		Decoder: TopLevelDecoder,
		Self.Output == Decoder.Input {
			tryMap { (o)  in
				do {
					let success = try successDecoder.decode(Success.self, from: o)
					return .success(success)
				} catch let sError {
					do {
						let f = try failureDecoder.decode(Failure.self, from:o)
						return .failure(f)
						
					} catch let fError {
						Swift.print(fError)
					}
					throw sError
				}
			}
			.eraseToAnyPublisher()
	}
}
public
extension URLSession.DataTaskPublisher {
	func handleResponse(_ handler: @escaping (Output)throws -> Void) -> AnyPublisher<Data, Error> {
		tryMap { (output) -> Data in
			try handler(output)
			return output.data
		}
		.eraseToAnyPublisher()
		
	}
}


extension Result:Decodable where Success: Decodable, Failure: Decodable {
	public init(from decoder: Decoder) throws {
		do {
			let s = try Success(from: decoder)
			self = .success(s)
			return
		} catch let sError {
			if let f = try? Failure(from: decoder) {
				self = .failure(f)
				return
			}
			throw sError
		}
	}
}

public extension Publisher {
	func sink(
		receiveValue: @escaping (Output) -> Void,
		endGracefully: (()->Void)? = nil,
		endWithError: @escaping (Error)->Void
	) -> AnyCancellable {
		sink(receiveCompletion: { (endding) in
			switch endding {
				case .finished: endGracefully?()
				case .failure(let error):
				endWithError(error)
			}
		}, receiveValue: receiveValue)
	}
}
