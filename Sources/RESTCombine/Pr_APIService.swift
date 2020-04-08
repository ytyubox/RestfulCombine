//
//  APIServiceTemplate.swift
//  HelperKit
//
//  Created by 游宗諭 on 2019/10/31.
//  Copyright © 2019 ytyubox. All rights reserved.
//
import Foundation
public typealias URLResult<Success, Fail> = (Result<Success, RESTError<Fail>>) where Success: Decodable, Fail: Decodable & Error
public typealias Then<Success, Fail> = (Result<Success, RESTError<Fail>>) -> Void where Success: Decodable, Fail: Decodable & Error

open class BasedService<DecodingAgent: DecodeAgent, EncodingAgent: EncodeAgent> {
	public typealias Task = URLSessionTask
	required public init(decoder: DecodingAgent, encoder: EncodingAgent, session: URLSession) {
		self.decoder = decoder
		self.encoder = encoder
		self.session = session
	}
	open var session: URLSession
	open var isDebug: Bool = false
	open var tempStr: String = ""
	open var decoder: DecodingAgent
	open var encoder: EncodingAgent
	
	
	open func fetch<Body, Success, Fail>(from api: APIEndPoint<Body, Success, Fail>,
																			 onConfig: ((inout URLRequest) -> Void)? = nil,
																			 retryCount: Int = 3,
																			 retryPreJob: ((() -> Void) -> Void)? = nil,
																			 then: @escaping (URLResult<Success, Fail>) -> Void) -> URLSessionTask
		where Body: Encoded, Body: Queryed, Success: Decodable, Fail: Decodable&Error {
			var request = api.request
			//                makeRequest(for: api)
			let isDebug = self.isDebug
			onConfig?(&request)
			//			request.niceDump()
			
			//			request.url!.parameters!.niceDump("query:")
			if let json = request.httpBody?.prettyPrintedJSONString {
				print("json:", json)
			}
			if let isFormdata = api.body as? IsFormData {
				//				isFormdata.formData.parameters.niceDump("formdata:")
			}
			let retryForEmptydata = api.retryForEmptydata
			let task = session.dataTask(with: request) { [request] (bodyData, response, error) in
				var result: URLResult<Success, Fail>
				var shouldHandleThen = true
				defer {
					if shouldHandleThen {
						DispatchQueue.main.async { then(result)}
					}
				}
				if let error = error {
					guard let customError = self.handleError(error as NSError) else {
						shouldHandleThen = false
						return result = .failure(.sessionError(error as! URLError))
					}
					return result = .failure(.other(customError))
				}
				
				
				let hr = response as! HTTPURLResponse
				let bool = self.shouldContinue(for: hr)
				if isDebug {
					//					hr.niceDump()
				}
				guard
					let data = bodyData,
					let str = String(data: data, encoding: .utf8)
					else { return result = .failure(.other(ERROR("no data")))}
				if str.isEmpty {
					dump(request)
					guard
						retryCount > 0,
						retryForEmptydata
						else {
							return result = .failure(.other(ERROR("APIError.retryNumberRunout")))
					}
					retryPreJob?({
						_ = self.fetch(from: api,
													 onConfig: onConfig,
													 retryCount: retryCount - 1,
													 retryPreJob: retryPreJob,
													 then: then)
					})
					result = .failure(.other(ERROR("🙂🙂🙂🙂🙂🙂🙂")))
					return shouldHandleThen = false
				}
				if let x = data.prettyPrintedJSONString {
					self.tempStr = "\(x)"
				} else {
					if isDebug {
						print(str)
					}
				}
				if let strategy =  self.decodeStrategy(for: hr) {
					var successError: DecodingError?
					do {
						let decoder = self.decoder(for: hr) ?? self.decoder
						switch strategy {
							case .success:
								do {
									let model = try decoder.decode(Success.self, from: data)
									result = .success(model)
									return
								} catch {
									successError = (error  as! DecodingError)
									fallthrough
							}
							
							case .failure:
								do {
									let fail = try decoder.decode(Fail.self, from: data)
									result = .failure(.apiFailure(fail))
								} catch {
									if isDebug {
										print("url:", response!.url!)
										print(successError!)
										print(str)
									}
									throw error
							}
							
							case .other(let s): result = .failure(.other(ERROR(s)))
						}
					} catch let failError  {
						result = .failure(
							.decodingError(
								DecodingDebugger(data: data, decodingError: successError!),
								DecodingDebugger(data: data, decodingError: failError as! DecodingError)
							)
						)
					}
					return
				}
				result = self.defaultDecoding(data, hr)
				
			}
			DispatchQueue.global().async {
				task.resume()
			}
			return task
	}
	open func willstartRequest() {
		
	}
	open func didStartRequest() {
		
	}
	open func shouldContinue(for response: HTTPURLResponse) -> Bool { true }
	public enum DecodeType {
		case success, failure, other(String)
		var isSuccess: Bool? {
			switch self {
				case .success: return true
				case .failure: return false
				case .other: return nil
			}
		}
	}
	open func decodeStrategy(for response: HTTPURLResponse) -> DecodeType? { nil }
	open func decoder(for response: HTTPURLResponse) -> DecodeAgent? {
		return nil
	}
	open func decodeSuccess<Success: Decodable>(data: Data, type: Success.Type) throws -> Success {
		try decoder.decode(type, from: data)
	}
	open func didgetSuccess<Success>(_ object: Success) {
		
	}
	
	open func decodeFailure<Fail: Decodable>(data: Data, type: Fail.Type) throws -> Fail {
		try decoder.decode(type, from: data)
	}
	open func didgetFailure<Fail>(_ object: Fail) {
		
	}
	open func handleError(_ error: NSError) -> Error? {
		// FIXBY: https://stackoverflow.com/questions/26411397/how-does-one-deal-with-a-cancelled-nsurlsessiontask-in-the-completion-handler-bl
		if error.code == NSURLErrorCancelled {return nil}
		return error
	}
	fileprivate func defaultDecoding<Success, Fail>(_ data: Data, _ hr: HTTPURLResponse) ->  URLResult<Success, Fail>
		where Success: Decodable, Fail: Decodable {
			var _sError: DecodingError?
			do {
				let model = try self.decoder.decode(Success.self, from: data)
				return .success(model)
			} catch let sError {
				if isDebug {
					_sError = sError as! DecodingError
					print(sError)
					print(hr.url!)
					print("data: ")
					print(data.prettyPrintedJSONString ?? "No data")
					print("header:")
				}
			}
			
			do {
				let apiFail = try self.decoder.decode(Fail.self, from: data)
				return  .failure(.apiFailure(apiFail))
			} catch let fError {
				if isDebug {
					print(fError)
				}
				return .failure(
					.decodingError(
						DecodingDebugger(data: data, decodingError: _sError!),
						DecodingDebugger(data: data, decodingError: fError as! DecodingError)
					)
				)
			}
	}
}
