//
//  File.swift
//  
//
//  Created by 游宗諭 on 2020/4/7.
//

import Foundation
public struct ContentType_ {
	public init(domain:String, type: String) {
		self.domain = domain
		self.type = type
	}
	var domain:String
	var type:String
	public var value:String {domain+"/"+type}
	public var key:String {Self.headerFaild}
	public func set(_ key:String,_ value: CustomStringConvertible) -> Self{
		Self(domain: domain, type: type + "\(key)=\(value)")
	}
}

// MARK: - Static member

public extension ContentType_ {
	static let headerFaild:String = "Content-Type"
	static let json = applictaion("json")
	static let urlEncode = applictaion("x-www-form-urlencoded")
	static let formData = multipart("formdata")
}

// MARK: - dot func
public extension ContentType_ {
	static func applictaion(_ type:String) -> ContentType_ {
		ContentType_(domain: "applictaion",type: type)
	}
	static func multipart(_ type: String) -> ContentType_ {
		ContentType_(domain: "multipart",type: type)
	}
	
	static func json(_ encoding: String.Encoding) -> Self {
		json.set("charset", encoding.description.uppercased())
	}
}
