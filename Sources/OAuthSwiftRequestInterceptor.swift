//
//  OAuthSwiftRequestInterceptor.swift
//  OAuthSwift-Alamofire
//
//  Created by phimage on 05/10/16.
//  Copyright © 2016 phimage. All rights reserved.
//

import Foundation
import Alamofire
import OAuthSwift

/// Add authentification headers from OAuthSwift to Alamofire request
open class OAuthSwiftRequestInterceptor: RequestInterceptor {

    fileprivate let oauthSwift: OAuthSwift
    public var paramsLocation: OAuthSwiftHTTPRequest.ParamsLocation = .authorizationHeader
    public var dataEncoding: String.Encoding = .utf8
    public var retryLimit = 1
    
    fileprivate var requestsToRetry: [(RetryResult) -> Void] = []

    public init(_ oauthSwift: OAuthSwift) {
        self.oauthSwift = oauthSwift
    }
    
    open func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var config = OAuthSwiftHTTPRequest.Config(
            urlRequest: urlRequest,
            paramsLocation: paramsLocation,
            dataEncoding: dataEncoding
        )
        config.updateRequest(credential: oauthSwift.client.credential)
        
        do {
            completion(.success(try OAuthSwiftHTTPRequest.makeRequest(config: config)))
        } catch {
            completion(.failure(error))
        }
    }
    
    open func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        completion(.doNotRetry)
    }
}

open class OAuthSwift2RequestInterceptor: OAuthSwiftRequestInterceptor {

    public init(_ oauthSwift: OAuth2Swift) {
        super.init(oauthSwift)
    }

    fileprivate var oauth2Swift: OAuth2Swift { return oauthSwift as! OAuth2Swift } // swiftlint:disable:this force_cast

    private let lock = NSLock() // lock required to manage requestToRetry access
    private var isRefreshing = false

    open override func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        lock.lock() ; defer { lock.unlock() }

        if mustRetry(request: request, dueTo: error) {
            // queue requests so they can all be retried when token refresh is done
            requestsToRetry.append(completion)
            
            if !isRefreshing {
                refreshTokens { [weak self] result in
                    guard let strongSelf = self else { return }

                    strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }

                    var shouldRetry: RetryResult
                    
                    switch result {
                    case .success:
                        shouldRetry = .retry
                    case .failure(let error):
                        shouldRetry = .doNotRetryWithError(error)
                    }
                    
                    // process any previously queued requests
                    strongSelf.requestsToRetry.forEach { $0(shouldRetry) }
                    strongSelf.requestsToRetry.removeAll()
                }
            }
        } else {
            completion(.doNotRetry)
        }
    }

    /// Determine if must retry or not ie. refresh token
    open func mustRetry(request: Request, dueTo error: Error) -> Bool {
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 && request.retryCount < retryLimit {
            return true
        }
        return false
    }

    private func refreshTokens(completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isRefreshing else { return }

        isRefreshing = true

        oauth2Swift.renewAccessToken(withRefreshToken: oauth2Swift.client.credential.oauthRefreshToken) { [weak self] result in
            guard let strongSelf = self else { return }
            
            // map success result from TokenSuccess to Void, and failure from OAuthSwiftError to Error
            let refreshResult = result.map { _ in () }.mapError { $0 as Error }
            completion(refreshResult)
            
            strongSelf.isRefreshing = false
        }
    }

}

extension OAuth1Swift {
    open var requestInterceptor: OAuthSwiftRequestInterceptor {
        return OAuthSwiftRequestInterceptor(self)
    }

}

extension OAuth2Swift {

    open var requestInterceptor: OAuthSwift2RequestInterceptor {
        return OAuthSwift2RequestInterceptor(self)
    }

}
