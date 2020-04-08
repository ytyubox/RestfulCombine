import Foundation
import SwiftContentType
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
	func dataTaskPublisherWithRestError<Body,Success,Failure>  (
		for endpoint: APIEndPoint<Body,Success,Failure>
	) ->  AnyPublisher<
		URLSession.DataTaskPublisher.Output,
		RESTError<Failure>
		>
		where Body: Encoded & Queryed, Success: Decodable, Failure: Decodable & Error {
			let request = endpoint.request
			return dataTaskPublisher(for: request).mapError {
				RESTError<Failure>.sessionError($0)
			}.eraseToAnyPublisher()
	}
}

struct RestCombine<Success,Failure,SCoder,Fcoder>
	where Success: Decodable, Failure:Decodable, Failure: Error,
	SCoder: TopLevelDecoder,
	Fcoder:TopLevelDecoder
{
	
	typealias Failure = RESTError<Failure>
	
	let publisher: URLSession.DataTaskPublisher
	
	private let _errorHandler:(RESTError<Failure>)->Void
	private let _valueHandler:(Success)->Void
	private let _responseHandler:(URLSession.DataTaskPublisher.Output)throws->Data
	typealias GetCoder<Coder> = (ContentType)->Coder where Coder: TopLevelDecoder
	private let _successDecoder: GetCoder<SCoder>
	private let _failureDecoder: GetCoder<Fcoder>
	
	public func errorHandler(_ then: @escaping (RESTError<Failure>)->Void) -> Self {
		RestCombine(publisher: publisher, _errorHandler: then, _valueHandler: _valueHandler, _responseHandler: _responseHandler,_successDecoder: _successDecoder,_failureDecoder: _failureDecoder)
	}
	public func valueHandler(_ then: @escaping (Success)->Void) -> Self {
		RestCombine(publisher: publisher, _errorHandler: _errorHandler, _valueHandler: then, _responseHandler: _responseHandler,_successDecoder: _successDecoder,_failureDecoder: _failureDecoder)
	}
	
	public func successDecoder<Coder>(_ getCoder: @escaping GetCoder<Coder>) -> RestCombine<Success,Failure,Coder,Fcoder> where Coder: TopLevelDecoder{
		RestCombine<Success,Failure,Coder,Fcoder>(publisher: publisher,
																							_errorHandler: _errorHandler,
																							_valueHandler: _valueHandler,
																							_responseHandler: _responseHandler,
																							_successDecoder: getCoder,
																							_failureDecoder: _failureDecoder)
	}
	public func failureDecoder<Coder>(_ getCoder: @escaping GetCoder<Coder>) -> RestCombine<Success,Failure,SCoder,Coder> where Coder: TopLevelDecoder{
		RestCombine<Success,Failure,SCoder,Coder>(publisher: publisher,
																							_errorHandler: _errorHandler,
																							_valueHandler: _valueHandler,
																							_responseHandler: _responseHandler,
																							_successDecoder: _successDecoder,
																							_failureDecoder: getCoder)
	}
	
	
	
	public func store<C>(in set: inout C) where C : RangeReplaceableCollection, C.Element == AnyCancellable {
		
		publisher
			.tryMap(_responseHandler)
			.mapError({ (e) -> RESTError<Failure> in
				if let u = e as? RESTError<Failure> {
					return u
				}
				return .other(e)
			})
			.decode(for: Success.self, fail: Failure.self, decoder: JSONDecoder())
			.sink(receiveValue: _valueHandler, endGracefully: nil, endWithError: _errorHandler)
		.store(in: &set)
		
	}
}


public
extension Publisher {
	func decode<Success,Failure,Decoder>(
		for successType: Success.Type,
		fail failureType: Failure.Type,
		decoder: Decoder
	) -> AnyPublisher<Success, RESTError<Failure>>
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
				do {
					let f = try decoder.decode(Failure.self, from: data)
					throw RESTError.apiFailure(f)
				} catch let fError as DecodingError {
					
					throw RESTError<Failure>.decodingError(
						DecodingDebugger(data: data as! Data, decodingError: sError!),
						DecodingDebugger(data: data as! Data, decodingError: fError)
					)
				}
			}
			.mapError {
				if let urlError =  $0 as? URLError {
					return RESTError<Failure>.sessionError(urlError)
				}
				return $0 as! RESTError<Failure>
				
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
		endWithError: @escaping (Failure)->Void
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
