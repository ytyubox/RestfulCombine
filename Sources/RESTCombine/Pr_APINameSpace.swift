//
//  Pr_APINameSpace.swift
//  HelperKit
//
//  Created by 游宗諭 on 2019/10/31.
//  Copyright © 2019 ytyubox. All rights reserved.
//

import Foundation

public
protocol APINameSpace {
	static var baseURL: String {get}
	static var urlTemplate: URLComponents {get}
	static func makeRequest<Body, Success, Fail>(for apiEnpoint: APIEndPoint<Body, Success, Fail>) -> URLRequest where Body: Queryed & Encoded, Success: Decodable, Fail: Decodable
	static var baseHeader: [String: String] {get}
}







public
extension APINameSpace {
	
	static var urlTemplate: URLComponents {URLComponents(string: Self.baseURL)!}
	
	static func makeRequest<Body, Success, Fail>(
		for api: APIEndPoint<Body, Success, Fail>
	) -> URLRequest
		where Body: Queryed & Encoded, Success: Decodable, Fail: Decodable {
			var  url  = URLComponents(string: Self.baseURL)!
			url.path += api.endpoint
			let bodyQueryDic = api.body?.queryDic ?? [:]
			let queryDic = api.baseQueryDic	 + bodyQueryDic
			url.query = queryDic.query
			assert(url.url != nil)
			assert(api.assertion)
			var request = URLRequest(url: url.url!)
			request.httpShouldHandleCookies = !api.ignoreCookie
			request.timeoutInterval = 15
			request.httpMethod = api.httpMethod.rawValue
			request.allHTTPHeaderFields = api.header
			request.allHTTPHeaderFields = Self.baseHeader + (api.specialHeader ?? [:])
			request.set(api.contentType)
			if api.contentType == .formData, let body = api.body as? IsFormData {
				let formData = body.formData
				request.httpBody = formData.encoded
				request.allHTTPHeaderFields = request.allHTTPHeaderFields! + formData.headerfield
			} else {
				request.httpBody = api.body?.encoded
			}
			return request
	}
}

// MARK: - fileprivate support
fileprivate
extension Dictionary {
	static var empty: [Key: Value] {[:]}
	/// replace key value for lhr if lhr and rhr have the same key
	/// += operater is problematic, using let new = l + r instade
	static func +(lhr: Dictionary<Key, Value>, rhr: Dictionary<Key, Value>)  -> Dictionary<Key, Value> {
		var copied = lhr
		for (k, v) in rhr {
			copied[k] = v
		}
		return copied
	}
	static func +(lhr: Dictionary<Key, Value>?, rhr: Dictionary<Key, Value>)  -> Dictionary<Key, Value> {
		guard var copied = lhr else { return rhr}
		for (k, v) in rhr {
			copied[k] = v
		}
		return copied
	}
}
fileprivate
extension Dictionary where Key  == String, Value: CustomStringConvertible {
	var query: String {
		let qlist = reduce([]) { $0 + [URLQueryItem(name: $1.key, value: $1.value.description)] }
		var r = URLComponents()
		r.queryItems = qlist
		return r.query!
	}
}
