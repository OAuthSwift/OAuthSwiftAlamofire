# OAuthSwiftAlamofire

<img  src="https://raw.githubusercontent.com/OAuthSwift/OAuthSwift/master/Assets/OAuthSwift-icon.png" alt="OAuthSwift" hspace=20 /> <img  src="https://raw.githubusercontent.com/Alamofire/Alamofire/assets/alamofire.png" alt="Alamofire" width = "400"/>



Utility methods to use `OAuthSwift` to sign `Alamofire` request.


## How to use
This framework provide a `RequestAdapter` to set into alamofire `SessionManager`
```swift
let sessionManager = SessionManager.default
sessionManager.adapter = oauthSwift.requestAdapter
```
Then you can make you request as usual
```swift
sessionManager.request("http://oauthbin.com/v1/echo")
```

:warning: you must have call `authorize` function on your `OAuthSwift`.
