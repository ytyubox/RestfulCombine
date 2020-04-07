//
//  File.swift
//  
//
//  Created by 游宗諭 on 2020/4/7.
//

import Foundation
public struct ContentType {
	public init(domain: String, type: String, attritube: [String : CustomStringConvertible] = [:]) {
		self.domain = domain
		self.type = type
		self.attritube = attritube
	}
	
	
	var domain:String
	var type:String
	var attritube:[String:CustomStringConvertible] = [:]
	public var value:String {
		let flags = attritube.count > 0 ?  attritube.reduce(into:" ;", {$0 += "\($1.key)=\($1.value)" }
			) : ""
		return domain+"/"+type + flags
	}
	public var key:String {Self.headerFaild}
	public func set(_ key:String,_ value: CustomStringConvertible) -> Self{
		Self(domain: domain, type: type, attritube: [key:value])
	}
}
extension ContentType: Equatable {
	public static func == (lhs: ContentType, rhs: ContentType) -> Bool {
		lhs.domain == rhs.domain && lhs.type == rhs.type
	}
	
}

// MARK: - Static member

public extension ContentType {
	static let headerFaild:String = "Content-Type"
	static let json = applictaion("json")
	static let urlEncode = applictaion("x-www-form-urlencoded")
	static let formData = multipart("formdata")
	static let plainText = text("plain")
}

// MARK: - dot func
public extension ContentType {
	static func applictaion(_ type:String) -> ContentType {
		ContentType(domain: "application",type: type)
	}
	static func multipart(_ type: String) -> ContentType {
		ContentType(domain: "multipart",type: type)
	}
	
	static func text(_ type: String) -> Self {
		ContentType(domain: "text", type: type)
	}
	static func json(_ encoding: String) -> Self {
		json.set("charset", encoding.uppercased())
	}
}


extension URLRequest {
	public mutating func set(_ contentType:ContentType?) {
		guard let contentType = contentType else {return}
		setValue(contentType.value, forHTTPHeaderField: contentType.key)
	}
}
