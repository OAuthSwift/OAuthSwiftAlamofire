# OAuthSwift-Alamofire

<img align="left" src="https://raw.githubusercontent.com/OAuthSwift/OAuthSwift/master/Assets/OAuthSwift-icon.png" alt="OAuthSwiftAlamofires" hspace="20" />
Utility methods to use `OAuthSwift` and `Alamofire`.

<br><br>
<br><br>
<br><br>


## How to use
### OAuth 2 & Manager
With OAuth version 2 you can get a new Alamofire `Manager` after authorization process. This manager will use as default headers the one computed by OAuthSwift.

```swift
let request = oauth2swift.manager()
```

### NSMutableRequest / URLRequestConvertible
On any `NSMutableRequest` use one of the `addOAuthHeader` to add `Authorization` HTTP header.

You can for instance use it in your `URLRequestConvertible` object before returning the `NSMutableURLRequest`.

### Alamofire Manager request methods
You can also use one of the new methods `request` on Alamofire `Manager` passing `OAuthSwiftCredential` as last parameters.

## TODO
- tests
- sample project
- cocoapod installation
