//
//  ERROR.swift
//  HelperKit
//
//  Created by 游宗諭 on 2019/12/2.
//  Copyright © 2019 ytyubox. All rights reserved.
//

import Foundation
public
struct ERROR: Error {

	public let message: String
	public init(_ m: String) {
		message = m
	}
	public var localizedDescription: String {message}
}

public struct DecodingDebugger {
	public let data:Data
	public let decodingError: DecodingError
	public var utf8String:String {String(data: data, encoding: .utf8)!}
}
public enum RESTError<T:Error>: Error {
	case sessionError(URLError)
	case apiFailure(T)
	case decodingError(DecodingDebugger,DecodingDebugger?)
	case other(Error)
}
