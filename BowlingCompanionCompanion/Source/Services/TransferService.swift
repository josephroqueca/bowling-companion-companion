//
//  TransferService.swift
//  BowlingCompanionCompanion
//
//  Created by Joseph Roque on 2018-10-29.
//  Copyright © 2018 Joseph Roque. All rights reserved.
//

import Foundation

class TransferService: Service {

	enum Status: String {
		case online = "Online"
		case offline = "Offline"
		case partiallyOnline = "Partial"
		case waiting = "Waiting"
		case error = "Error"
	}

	struct Endpoint: Decodable {
		let name: String
		let status: Bool
	}

	let url: URL
	let apiKey: String

	private(set) var status: Status = .waiting
	private(set) var endpoints: [Endpoint] = []

	init(url: String, apiKey: String) {
		self.url = URL(string: url)!
		self.apiKey = apiKey
	}

	private var statusEndpoint: URL {
		return URL(string: "api", relativeTo: url)!
	}

	private func buildURLRequest(for url: URL) -> URLRequest {
		var urlRequest = URLRequest(url: url)
		urlRequest.addValue(apiKey, forHTTPHeaderField: "Authorization")
		urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
		return urlRequest
	}

	func query(delegate: URLSessionDelegate, completion: @escaping () -> Void) {
		queryStatus(urlSessionDelegate: delegate, completion: completion)
	}

	func queryStatus(urlSessionDelegate delegate: URLSessionDelegate, completion: @escaping () -> Void) {
		let queryRequest = buildURLRequest(for: statusEndpoint)
		let session = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: OperationQueue.main)
		let task = session.dataTask(with: queryRequest) { [weak self] data, response, error in
			guard let self = self else { return }
			let decoder = JSONDecoder()
			do {
				if let data = data {
					let	endpoints = try decoder.decode([Endpoint].self, from: data)
					self.endpoints = endpoints
					if endpoints.count > 0 && endpoints.allSatisfy({ $0.status == true }) {
						self.status = .online
					} else {
						self.status = .partiallyOnline
					}
				} else if let error = error {
					self.status = .error
					print("Error accessing server: \(error)")
				} else {
					self.status = .offline
				}
			} catch let error {
				print("Error decoding server response: \(error)")
				self.status = .error
			}

			DispatchQueue.main.async {
				completion()
			}
		}

		DispatchQueue.global(qos: .background).async {
			task.resume()
		}
	}
}
