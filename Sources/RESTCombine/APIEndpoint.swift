//
//  APIEndpoint.swift
//  sportsAPI
//
//  Created by 游宗諭 on 2019/8/26.
//  Copyright © 2019 ytyubox. All rights reserved.
//

import Foundation


public
struct APIEndPoint<Body: Encoded & Queryed, Success: Decodable, Failure: Decodable> {
	public let SuccessType: Success.Type
	public let FailureType: Failure.Type
	public var apiList: APINameSpace.Type
	public let endpoint: String
	public var header = [String: String]()
	public var body: Body!
	public let httpMethod: HttpMethod
	public var contentType: ContentType?
	public let s: Success?
	public let f: Failure?
	public var baseQueryDic: [String: String]?
	public var specialHeader: [String: String]?
	public var retryForEmptydata = true
	public var ignoreCookie = false
	public var assertion: Bool { return !(httpMethod == .GET && contentType != nil && body != nil) }
	public
	init(endpoint: String,
		 httpMethod: HttpMethod,
		 contentType: ContentType?,
		 apiList: APINameSpace.Type) {
		self.endpoint = endpoint
		self.httpMethod = httpMethod
		self.contentType = contentType
		self.s = nil
		self.f = nil
		SuccessType = Success.self
		FailureType = Failure.self
		self.apiList = apiList
	}
	public var request: URLRequest {
		apiList.makeRequest(for: self)
	}
}
public enum ContentType: CaseIterable {
	init(_ contentType: ContentType, field: [String: String] = [:]) {
		self = contentType

	}
	public init?(header: [String: String]?) {
		guard
			let typeString = header?["Content-Type"],
			let rawSubString = typeString.split(separator: ";").first
			else {return nil}
		let rawString = String(rawSubString).lowercased()
		for _type in Self.allCases {
			if rawString == _type.contentString {self = _type}
		}
		return nil
	}
	case json
	case urlEncode
	case formData
	case plain

	var rawValue: String {
		switch self {
			case .json: return "application/json"
			case .urlEncode: return "application/x-www-form-urlencoded"
			case .formData: return ("⛔️ formdata need boundary for header")
			case .plain: return "text/plain"
		}
	}
	private var contentString: String {
		switch self {
			case .json: return "application/json; charset=UTF-8"
			case .urlEncode: return "application/x-www-form-urlencoded"
			case .formData: return ("multipart/form-data")
			/*
			application/EDI-X12
			application/EDIFACT
			application/javascript
			application/octet-stream
			application/ogg
			application/pdf
			application/xhtml+xml
			application/x-shockwave-flash
			application/json
			application/ld+json
			application/xml
			application/zip
			application/x-www-form-urlencoded
			*/
			case .plain: return "text/plain ;charset=UTF-8"
		}
	}

	public func add(to request: inout URLRequest) {

		request.setValue(self.contentString, forHTTPHeaderField: Self.headerKey)
	}
	static var headerKey: String {"Content-Type"}
}
public
enum HttpMethod: String {
	case GET, POST, PUT, DELETE
}
