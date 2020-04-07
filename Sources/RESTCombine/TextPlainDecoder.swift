//
//  TextPlainDecoder.swift
//  HelperKit
//
//  Created by 游宗諭 on 2020/3/3.
//  Copyright © 2020 ytyubox. All rights reserved.
//

import Foundation

public
struct TextPlainDecoder: DecodeAgent {
	public init() { }
	public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
		guard T.self == String.self else {throw ERROR("T is not String")}
		guard let result = String(data: data, encoding: .utf8) else { throw ERROR("data cannot convert into String: \(data)") }

		return result as! T
	}

}
