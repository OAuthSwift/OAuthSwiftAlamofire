//
//  Manager+OAuthSwift.swift
//  OAuthSwift-Alamofire
//
//  Created by phimage on 27/09/15.
//  Copyright © 2015 phimage. All rights reserved.
//

import Foundation
import OAuthSwift
import Alamofire


extension Manager {

    public func request(
        method: Alamofire.Method,
        _ URLString: URLStringConvertible,
        parameters: [String: AnyObject]? = nil,
        encoding: ParameterEncoding = .URL,
        credential: OAuthSwiftCredential)
        -> Request
    {
        let headers = credential.makeHeaders(NSURL(string: URLString.URLString)!, method: method.oauth, parameters: parameters ?? [:])
        
        return request(method, URLString,
            parameters: parameters,
            encoding: encoding,
            headers: headers)
    }

    public func request(URLRequest: URLRequestConvertible, credential: OAuthSwiftCredential) -> Request {
        let request = URLRequest.URLRequest
        request.addOAuthHeader(credential)
        let requestConvertible: URLRequestConvertible = request
        return self.request(requestConvertible)
    }

}
