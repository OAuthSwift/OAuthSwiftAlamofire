//
//  OAuthSwiftRequestAdapter.swift
//  OAuthSwift-Alamofire
//
//  Created by phimage on 05/10/16.
//  Copyright © 2016 phimage. All rights reserved.
//

import Foundation
import Alamofire
import OAuthSwift

// Add authentification headers from OAuthSwift to Alamofire request
open class OAuthSwiftRequestAdapter: RequestAdapter {
    
    fileprivate let oauthSwift: OAuthSwift
    public var paramsLocation: OAuthSwiftHTTPRequest.ParamsLocation = .authorizationHeader
    public var dataEncoding: String.Encoding = .utf8

    public init(_ oauthSwift: OAuthSwift) {
        self.oauthSwift = oauthSwift
    }

    public func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var config = OAuthSwiftHTTPRequest.Config(
            urlRequest: urlRequest,
            paramsLocation: paramsLocation,
            dataEncoding: dataEncoding
        )
        config.updateRequest(credential: oauthSwift.client.credential)
        
        return try OAuthSwiftHTTPRequest.makeRequest(config: config)
    }

}

open class OAuthSwift2RequestAdapter: OAuthSwiftRequestAdapter, RequestRetrier {
    
    public init(_ oauthSwift: OAuth2Swift) {
        super.init(oauthSwift)
    }

    fileprivate var oauth2Swift: OAuth2Swift { return oauthSwift as! OAuth2Swift }

    private let lock = NSLock()
    private var isRefreshing = false
    private var requestsToRetry: [RequestRetryCompletion] = []
    
    public func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        lock.lock() ; defer { lock.unlock() }
        
        if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
            requestsToRetry.append(completion)
            
            if !isRefreshing {
                refreshTokens { [weak self] succeeded in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }

                    strongSelf.requestsToRetry.forEach { $0(succeeded, 0.0) }
                    strongSelf.requestsToRetry.removeAll()
                }
            }
        } else {
            completion(false, 0.0)
        }
    }
    
    private typealias RefreshCompletion = (_ succeeded: Bool) -> Void

    private func refreshTokens(completion: @escaping RefreshCompletion) {
        guard !isRefreshing else { return }
        
        isRefreshing = true
        
        
        oauth2Swift.renewAccessToken(
            withRefreshToken: "",
            success: { [weak self] (credential, response, parameters) in
                guard let strongSelf = self else { return }
                completion(true)
                strongSelf.isRefreshing = false
            }, failure: { [weak self] (error) in
                guard let strongSelf = self else { return }
                completion(false)
                strongSelf.isRefreshing = false
            }
        )

    }
    
}

extension OAuth1Swift {
    
    open var requestAdapter: OAuthSwiftRequestAdapter {
        return OAuthSwiftRequestAdapter(self)
    }
    
}

extension OAuth2Swift {
    
    open var requestAdapter: OAuthSwift2RequestAdapter {
        return OAuthSwift2RequestAdapter(self)
    }
    
}
