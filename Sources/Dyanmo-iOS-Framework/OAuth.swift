//
//  File.swift
//  
//
//  Created by Akashchellakumar on 10/09/20.
//

import Foundation
import os
@available(iOS 10.0, *)
public class OAuth {
    public init() {}
    
    var session: URLSession?
    
    public func retriveOAuthToken(userDetails: UserDetails, serverDetails: OAuthServerDetails, tokenIdentifier: TokenIdentifier, completion: @escaping (OAuthToken?,Error?) -> ()) {
        os_log("Entering retriveOAuthToken()", log: OSLog.dyanmoiOSFramework, type: .info)
        
        if IsvalidParameter(userDetails: userDetails, serverDetails: serverDetails, tokenIdentifier: tokenIdentifier) {
            let tokenId = tokenIdentifier.access_token_id
            let accessTokenId = tokenId + ACCESS_TOKEN
            let refreshTokenId = tokenId + REFRESH_TOKEN
            let expireTimeId = tokenId + EXPIRE_TIME
            
            let existingAccessToken = UserDefaults.standard.string(forKey: accessTokenId)
            let existingRefreshToken = UserDefaults.standard.string(forKey: refreshTokenId)
            let existingExpireTime = UserDefaults.standard.object(forKey: expireTimeId) as? Date
            
            if let accessToken = existingAccessToken, let refreshToken = existingRefreshToken, let expireTime = existingExpireTime {
                IsAccessTokenExpired(accessTokenExpiryTime: expireTime) { bool in
                    if bool == false {
                        os_log("The Current Access Token is valid", log: OSLog.dyanmoiOSFramework,type: .info)
                        let oAuthToken = OAuthToken(access_token: accessToken)
                        completion(oAuthToken,nil)
                    } else {
                        let serverDetail = OAuthServerDetails(serverUrl: serverDetails.serverUrl, clientId: serverDetails.clientId, clientSecert: serverDetails.clientSecret, grantType: GRANT_TYPE_REFRESH_TOKEN)
                        self.updateAndStoreOAuthToken(userDetails: userDetails, serverDetails: serverDetail, tokenIdentifier: tokenIdentifier, refreshToken: refreshToken) { oAuth, error in
                            if error == nil {
                                guard let oAuth = oAuth else { return }
                                completion(oAuth,nil)
                            } else {
                                self.updateAndStoreOAuthToken(userDetails: userDetails, serverDetails: serverDetails, tokenIdentifier: tokenIdentifier, refreshToken: nil) { oAuth, error in
                                    if error == nil {
                                        guard let oAuth = oAuth else { return }
                                        completion(oAuth,nil)
                                    }
                                }
                            }
                        }
                    }
                }
                
            } else {
                updateAndStoreOAuthToken(userDetails: userDetails, serverDetails: serverDetails, tokenIdentifier: tokenIdentifier, refreshToken: nil) { oAuth, error in
                    if error == nil {
                        guard let oAuth = oAuth else { return }
                        completion(oAuth,nil)
                    }else{
                        completion(nil,error)
                    }
                }
            }
        } else {
            os_log("Invalid Parameters : Any of the Parameter can be Empty", log: OSLog.dyanmoiOSFramework, type: .error)
        }
        os_log("Leaving retriveOAuthToken()", log: OSLog.dyanmoiOSFramework, type: .info)
    }
    
    private func IsvalidParameter(userDetails: UserDetails, serverDetails: OAuthServerDetails, tokenIdentifier: TokenIdentifier) -> Bool {
        os_log("Entering IsvalidParameter()", log: OSLog.dyanmoiOSFramework, type: .info)
        let userDetail = !userDetails.userName.isEmpty && !userDetails.password.isEmpty
        let serverDetail = !serverDetails.clientId.isEmpty && !serverDetails.clientSecret.isEmpty && !serverDetails.grantType.isEmpty && !serverDetails.serverUrl.isEmpty
        let tokenId = !tokenIdentifier.access_token_id.isEmpty
        os_log("Leaving IsvalidParameter()", log: OSLog.dyanmoiOSFramework, type: .info)
        return userDetail && serverDetail && tokenId
    }
    

    private func updateAndStoreOAuthToken(userDetails: UserDetails, serverDetails: OAuthServerDetails, tokenIdentifier: TokenIdentifier, refreshToken: String?, completion: @escaping (OAuthToken?, Error?) -> ()) {
        os_log("Entering retriveAndStoreOAuthToken(). Username = %@ , password = %@", log: OSLog.dyanmoiOSFramework, type: .info, userDetails.userName, userDetails.password)
        
        guard let url = URL(string: getOAuthAccessTokenUrl(userDetails: userDetails, serverDetails: serverDetails, tokenIdentifier: tokenIdentifier, refreshToken: refreshToken)) else {
            os_log("Error while drafting the url to fetch the access token", log: OSLog.dyanmoiOSFramework, type: .error)
            return
        }
        
        os_log("URL = %@", log: OSLog.dyanmoiOSFramework, type: .info, url as CVarArg)
        
        let request = NSMutableURLRequest(url: url)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            data, _, error in
            
            if let error = error {
                print(error)
                os_log("Error = %@", log: OSLog.dyanmoiOSFramework, type: .error, error as NSError)
            } else {
                if let unwrappedData = data {
                    if let tokenDetails = String(data: unwrappedData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
                        os_log("Received OAuthAccessToken. Details: %@", log: OSLog.dyanmoiOSFramework, type: .info, tokenDetails)
                        do {
                            if let data = tokenDetails.data(using: .utf8) {
                                let oauthToken = try JSONDecoder().decode(ParseOAuthToken.self, from: data)
                                print("Received OAuthAccessToken. Details:\(oauthToken)")
                                
                                let oAuth = self.storeOAuthToken(accessObject: oauthToken, tokenIdentidier: tokenIdentifier)
                                DispatchQueue.main.sync {
                                    completion(oAuth, nil)
                                }
                            } else {
                                os_log("No encoded data present", log: OSLog.dyanmoiOSFramework, type: .error)
                            }
                        } catch let error as NSError {
                            os_log("Error = %@", log: OSLog.dyanmoiOSFramework, type: .error, error)
                            DispatchQueue.main.sync {
                                completion(nil, error)
                            }
                        }
                    } else {
                        os_log("Error while encoding the data returned by Dynamo server", log: OSLog.dyanmoiOSFramework, type: .error)
                    }
                }
            }
               })
        task.resume()
        os_log("Leaving retriveAndStoreOAuthToken().", log: OSLog.dyanmoiOSFramework, type: .info)
    }
    
     private func storeOAuthToken(accessObject: ParseOAuthToken, tokenIdentidier: TokenIdentifier) -> OAuthToken {
        os_log("Entering storeOAuthToken()", log: OSLog.dyanmoiOSFramework, type: .info)
        
        let oAuth = OAuthToken(access_token: accessObject.access_token)
        
        let tokenId = tokenIdentidier.access_token_id
        let accessTokenId = tokenId + ACCESS_TOKEN
        let refreshTokenId = tokenId + REFRESH_TOKEN
        let expireTimeId = tokenId + EXPIRE_TIME
        
        UserDefaults.standard.set(accessObject.access_token, forKey: accessTokenId)
        UserDefaults.standard.set(accessObject.refresh_token, forKey: refreshTokenId)
        
        let now = Date()
        let expirationTimeForAccessToken = now.addingTimeInterval(TimeInterval(accessObject.expires_in))
        
        UserDefaults.standard.set(expirationTimeForAccessToken, forKey: expireTimeId)
        
        os_log("Leaving storeOAuthToken()", log: OSLog.dyanmoiOSFramework, type: .info)
        return oAuth
    }
    
    private func IsAccessTokenExpired(accessTokenExpiryTime: Date, completion: @escaping (Bool) -> ()) {
        os_log("Entering IsAccessTokenValid() Expire Time = %@", log: OSLog.dyanmoiOSFramework, type: .info,accessTokenExpiryTime as CVarArg)
        let now = Date()
        os_log("Current Time = %@", log : OSLog.dyanmoiOSFramework,type: .info,now as CVarArg)
        if now >= accessTokenExpiryTime {
            completion(true)
        } else {
            completion(false)
        }
        os_log("Leaving IsAccessTokenValid()", log: OSLog.dyanmoiOSFramework, type: .info)
    }
    
    public func authorizeAppWithOAuthAccessToken(with token: String) {
        os_log("Entering authorizeAppWithOAuthAccessToken(). Token = %@", log: OSLog.dyanmoiOSFramework, type: .info, token)
        
        let sessionConfiguration = URLSessionConfiguration.default
        var headers = sessionConfiguration.httpAdditionalHeaders ?? [:]
        headers["Authorization"] = "Bearer \(token)"
        sessionConfiguration.httpAdditionalHeaders = headers
        session = URLSession(configuration: sessionConfiguration)
        os_log("Leaving authorizeAppWithOAuthAccessToken()", log: OSLog.dyanmoiOSFramework, type: .info)
    }
    
    public func invalidateToken(tokenIdentifier: TokenIdentifier) -> Bool {
        let tokenId = tokenIdentifier.access_token_id
        let accessTokenId = tokenId + ACCESS_TOKEN
        let refreshTokenId = tokenId + REFRESH_TOKEN
        let expireTimeId = tokenId + EXPIRE_TIME
        
        UserDefaults.standard.removeObject(forKey: accessTokenId)
        UserDefaults.standard.removeObject(forKey: refreshTokenId)
        UserDefaults.standard.removeObject(forKey: expireTimeId)
        return true
    }
    
    private func getOAuthAccessTokenUrl(userDetails: UserDetails, serverDetails: OAuthServerDetails, tokenIdentifier: TokenIdentifier, refreshToken: String?) -> String {
        os_log("Entering getOAuthAccessTokenUrl().", log: OSLog.dyanmoiOSFramework, type: .info)
        
        var finalUrl = String()
        
        let clientId = CLIENT_ID_URL + serverDetails.clientId
        let grantType = GRANT_TYPE_URL + serverDetails.grantType
        let clientsecret = CLIENT_SECERT_URL + serverDetails.clientSecret
        
        if serverDetails.grantType == GRANT_TYPE_PASSWORD {
            let username = USERNAME_URL + userDetails.userName
            let password = PASSWORD_URL + userDetails.password
            
            finalUrl = serverDetails.serverUrl + OAUTHTOKEN_URL + clientId + clientsecret + grantType + username + password
            
        } else if serverDetails.grantType == GRANT_TYPE_REFRESH_TOKEN {
            if let refresh = refreshToken {
                let refresh_token = REFRESH_TOKEN_URL + refresh
                finalUrl = serverDetails.serverUrl + OAUTHTOKEN_URL + clientId + clientsecret + grantType + refresh_token
                
            } else {
                os_log("Error in generating url to get the acces token", log: OSLog.dyanmoiOSFramework, type: .error)
            }
        }
        os_log("Leaving getOAuthAccessTokenUrl().", log: OSLog.dyanmoiOSFramework, type: .info)
        return finalUrl
    }
}

@available(iOS 10.0, *)
extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!
    static let dyanmoiOSFramework = OSLog(subsystem: subsystem, category: "dynamoiOSFramework")
}

