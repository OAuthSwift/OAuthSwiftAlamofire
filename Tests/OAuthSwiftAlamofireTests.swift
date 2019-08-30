//
//  OAuthSwiftAlamofireTests.swift
//  OAuthSwiftAlamofireTests
//
//  Created by phimage on 06/10/16.
//  Copyright © 2016 phimage. All rights reserved.
//

import XCTest
@testable import OAuthSwiftAlamofire
import OAuthSwift
import Alamofire

class OAuthSwiftAlamofireTests: XCTestCase {
    
    let callbackURL = "test://callback"
    let oauth = OAuth1Swift(
        consumerKey: "key",
        consumerSecret: "secret",
        requestTokenUrl: "http://oauthbin.com/v1/request-token",
        authorizeUrl: "automatic://host/autorize",
        accessTokenUrl: "http://oauthbin.com/v1/access-token"
    )
    
    override func setUp() {
        super.setUp()
        oauth.allowMissingOAuthVerifier = true
        oauth.authorizeURLHandler = TestOAuthSwiftURLHandler(
            callbackURL: callbackURL,
            authorizeURL: "automatic://host/autorize",
            version: .oauth1
        )
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOAuthbinSuccess() {
        let expectation = self.expectation(description: "auth should succeed")
        
        oauth.authorize(
        withCallbackURL: URL(string:callbackURL)!) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure (let error):
                XCTFail("The failure handler should not be called. \(error)")
            }
        }
        
        waitForExpectations(timeout: 20, handler: nil)
        
        let oauth_token = "accesskey"
        let oauth_token_secret = "accesssecret"
        XCTAssertEqual(oauth.client.credential.oauthToken, oauth_token)
        XCTAssertEqual(oauth.client.credential.oauthTokenSecret, oauth_token_secret)
    }
    
    func testAlamofire() {
        if oauth.client.credential.oauthToken.isEmpty {
            testOAuthbinSuccess()
        }
        
        let expectation = self.expectation(description: "auth should succeed")
        let interceptor = oauth.requestInterceptor
        let sessionManager = Session(interceptor: interceptor)
        let param = "method=foo&bar=baz"
        // TODO http://oauthbin.com no more exist, test could not be done
        sessionManager.request("http://oauthbin.com/v1/echo?\(param)", method: .get).validate().responseString { response in
            switch response.result {
            case .success(let value):
                XCTAssertEqual(param, value)
                expectation.fulfill()
            case .failure(let e):
                XCTFail("The failure handler should not be called. \(e)")
            }
        }
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    // Note: oauthbin.com doesn't seem to exist anymore (domain name expire) and couldn't find another easily usable test server
    // This test case needs to be updated if and when oauthbin.com comes back.
    func testMultipleRequests() {
        let exp1 = self.expectation(description: "auth should retry 1st request")
        let exp2 = self.expectation(description: "auth should retry 2nd request")
        
        let oauth2 = OAuth2Swift(
            consumerKey: "tbd",
            consumerSecret: "tbd",
            authorizeUrl: "tbd",
            accessTokenUrl: "tbd",
            responseType: "code")
        
        let interceptor = oauth2.requestInterceptor
        let session = Session(interceptor: interceptor)
        
        session.request("tbd", method: .get).validate().response { response in
            XCTAssert(response.response?.statusCode == 200, "Failed request 1 auth")
            exp1.fulfill()
        }
        
        session.request("tbd").validate().response { response in
            XCTAssert(response.response?.statusCode == 200, "Failed request 2 auth")
            exp2.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
    }

}


// MARK: FROM Xcode test
class TestOAuthSwiftURLHandler: NSObject, OAuthSwiftURLHandlerType {
    
    let callbackURL: String
    let authorizeURL: String
    let version: OAuthSwiftCredential.Version
    
    var accessTokenResponse: AccessTokenResponse?
    
    var authorizeURLComponents: URLComponents? {
        return URLComponents(url: URL(string: self.authorizeURL)!, resolvingAgainstBaseURL: false)
    }
    
    init(callbackURL: String, authorizeURL: String, version: OAuthSwiftCredential.Version) {
        self.callbackURL = callbackURL
        self.authorizeURL = authorizeURL
        self.version = version
    }
    @objc func handle(_ url: URL) {
        switch version {
        case .oauth1:
            handleV1(url)
        case .oauth2:
            handleV2(url)
        }
    }
    
    func handleV1(_ url: URL) {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        if let queryItems = urlComponents?.queryItems {
            for queryItem in queryItems {
                if let value = queryItem.value , queryItem.name == "oauth_token" {
                    let url = "\(self.callbackURL)?oauth_token=\(value)"
                    OAuthSwift.handle(url: URL(string: url)!)
                }
            }
        }
        
        urlComponents?.query = nil
        
        if urlComponents != authorizeURLComponents  {
            print("bad authorizeURL \(url), must be \(authorizeURL)")
            return
        }
        
        // else do nothing
    }
    
    func handleV2(_ url: URL) {
        var url = "\(self.callbackURL)/"
        if let response = accessTokenResponse {
            switch response {
            case .accessToken(let token):
                url += "?access_token=\(token)"
            case .code(let code, let state):
                url += "?code='\(code)'"
                if let state = state {
                    url += "&state=\(state)"
                }
            case .error(let error,let errorDescription):
                let e = error.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let ed = errorDescription.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                url += "?error='\(e)'&errorDescription='\(ed)'"
            case .none: break
                // nothing
            }
        }
        OAuthSwift.handle(url: URL(string: url)!)
    }
}


enum AccessTokenResponse {
    case accessToken(String), code(String, state:String?), error(String,String), none
    
    var responseType: String {
        switch self {
        case .accessToken:
            return "token"
        case .code:
            return "code"
        case .error:
            return "code"
        case .none:
            return "code"
        }
    }
}
