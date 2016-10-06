//
//  HTTPMethod.swift
//  OAuthSwift-Alamofire
//
//  Created by phimage on 07/01/16.
//  Copyright © 2016 phimage. All rights reserved.
//

import Foundation
import Alamofire
import OAuthSwift

public extension Alamofire.HTTPMethod {

    public var oauth: OAuthSwiftHTTPRequest.Method {
        return OAuthSwiftHTTPRequest.Method(rawValue: self.rawValue)!
    }

}

public extension OAuthSwiftHTTPRequest.Method {
    
    public var alamofire: Alamofire.HTTPMethod {
        return Alamofire.HTTPMethod(rawValue: self.rawValue)!
    }

}
