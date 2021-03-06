//
//  File.swift
//  
//
//  Created by 游宗諭 on 2020/4/8.
//

import XCTest
import RESTCombine

enum TodoList: APINameSpace {
	static var baseURL: String = "http://localhost:8080/api/"
	
	static var baseHeader: [String : String] = [:]
	static let user = APIEndPoint<UserBody, UserResponse, TodoError>(endpoint: "users",
																																	 httpMethod: .GET,
																																	 contentType: nil,
																																	 apiList: Self.self)
}

struct UserBody:Body {
	var encoded: Data?
	var queryDic: [String : String] {[:]}
}

struct UserResponse: Decodable {
	var id: UUID
	var name: String
	var username: String
}

struct TodoError:Decodable,Error {
	
	let error:Bool
	let reason:String
	
}
class TodoListTests: XCTestCase {
	
	
	func testUserTwoDecoder() {
		let await = XCTestExpectation()
		var sinks = SinkBags()
		URLSession.shared.dataTaskPublisher(for: TodoList.user)
			.map(\.data)
			.twoDecode([UserResponse].self, TodoError.self, decoder: JSONDecoder())
			.sink(receiveCompletion: {print($0)}) { (r) in
				print(r)
				await.fulfill()
		}.store(in: &sinks)
		wait(for: [await], timeout: 15)
	}
	func testUser() {
		let await = XCTestExpectation()
		var sinks = SinkBags()
		var usr = TodoList.user
		usr.endpoint = "users"
		
		
		URLSession.shared.dataTaskPublisher(for: usr)
			.map(\.data)
			.decode(for: [UserResponse].self,fail: TodoError.self, decoder: JSONDecoder())
			.sink(receiveCompletion: {
				switch $0 {
					case .failure(let e):
						switch e {
							case .sessionError(let urlError): print("urlError\n",urlError)
							case .apiFailure(let apiF): print("apiF\n",apiF)
							case .decodingError(let s, let f):print("s\n",s,"\nf\n", f)
							case .other(let e): print("e\n",e)
					}
					
					case .finished: break
				}
				await.fulfill()
			}) { (r) in
				print(r)
		}.store(in: &sinks)
		
		wait(for: [await], timeout: 15)
	}
	func testUserWithRestError() {
		let await = XCTestExpectation()
		var sinks = SinkBags()
		var usr = TodoList.user
		usr.endpoint = "user"
		
		
		URLSession.shared.dataTaskPublisherWithRestError(for: usr)
			.map(\.data)
			.decode(for: [UserResponse].self,fail: TodoError.self, decoder: JSONDecoder())
			.sink(receiveCompletion: {
				switch $0 {
					case .failure(let e):
						switch e {
							case .sessionError(let urlError):
								print("urlError\n",urlError)
							case .apiFailure(let apiF):
								print("apiF\n",apiF)
							case .decodingError(let s, let f):
								print("s\n",s,"\nf\n", f!)
							case .other(let e):
								print("e\n",e)
					}
					
					case .finished: break
				}
				await.fulfill()
			}) { (r) in
				print(r)
		}.store(in: &sinks)
		
		wait(for: [await], timeout: 15)
	}
}
