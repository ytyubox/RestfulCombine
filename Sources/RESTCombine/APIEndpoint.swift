//
//  APIEndpoint.swift
//  sportsAPI
//
//  Created by 游宗諭 on 2019/8/26.
//  Copyright © 2019 ytyubox. All rights reserved.
//

import Foundation
import SwiftContentType


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
		 apiList: APINameSpace.Type,
		 body: Body? = nil) {
		self.endpoint = endpoint
		self.httpMethod = httpMethod
		self.contentType = contentType
		self.s = nil
		self.f = nil
		SuccessType = Success.self
		FailureType = Failure.self
		self.apiList = apiList
		self.body = nil
	}
	public var request: URLRequest {
		apiList.makeRequest(for: self)
	}
}

public
enum HttpMethod: String {
	case GET, POST, PUT, DELETE
}
