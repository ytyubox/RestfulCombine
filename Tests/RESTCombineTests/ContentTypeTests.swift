//
//  File.swift
//  
//
//  Created by 游宗諭 on 2020/4/7.
//

import XCTest
import RESTCombine

class ContentTypeTests: XCTestCase {
	func testContentType() {
		XCTAssertEqual(ContentType.json.value, "application/json")
		XCTAssertEqual(ContentType.urlEncode.value, "application/x-www-form-urlencoded")
		XCTAssertEqual(ContentType.formData.value, "multipart/formdata")
		XCTAssertEqual(ContentType.plainText.value, "text/plain")
		XCTAssertEqual(ContentType.json("utf-8").value, "application/json ;charset=UTF-8")
	}
}
