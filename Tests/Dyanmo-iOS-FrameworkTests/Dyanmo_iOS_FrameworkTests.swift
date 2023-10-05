import XCTest
@testable import Dyanmo_iOS_Framework

@available(iOS 10.0, *)
final class Dyanmo_iOS_FrameworkTests: XCTestCase {
    
    var oAuth = OAuth()

    
    override func setUp() {
        oAuth = OAuth()

    }
    
    func IsvalidParameterTest(){
         let user = UserDetails(userName: "", password: "carejoy123")
        let serverDetail = OAuthServerDetails(serverUrl: "https://refresh.health:8443", clientId: "dynamo-oauth2-client", clientSecert: "karthik", grantType: "password")
        let tokenID = TokenIdentifier(accessTokenId: "com.TestingDyanmoIoSFramework")
        XCTAssertTrue( oAuth.IsvalidParameter(userDetails: user, serverDetails: serverDetail, tokenIdentifier: tokenID))

    }
    
    func IsAccessTokenExpiredTest(){
        let now = Date()
        oAuth.IsAccessTokenExpired(accessTokenExpiryTime: now) { (bool) in
            XCTAssertTrue(bool)
        }
    }
    
    func storeOAuthTokenTest(){
        let parseToken = ParseOAuthToken(access_token: "AKash", expires_in: 299, refresh_token: "", scope: "", token_type: "")
        let tokenID = TokenIdentifier(accessTokenId: "com.TestingDyanmoIoSFramework")
        let oauth = oAuth.storeOAuthToken(accessObject: parseToken, tokenIdentidier: tokenID)
        XCTAssertEqual(oauth.access_token, "AKash")
    }
    
    func invalidateTokenTest(){
        let tokenID = TokenIdentifier(accessTokenId: "com.TestingDyanmoIoSFramework")
        XCTAssertTrue( oAuth.invalidateToken(tokenIdentifier: tokenID))
    }
 
}

