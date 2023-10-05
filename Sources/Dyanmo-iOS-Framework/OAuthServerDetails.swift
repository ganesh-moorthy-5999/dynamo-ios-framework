//
//  File.swift
//  
//
//  Created by Akashchellakumar on 10/09/20.
//

import Foundation

public struct OAuthServerDetails {
    
     let serverUrl: String
     let clientId: String
     let clientSecret: String
     let grantType: String
    
    public init (serverUrl: String ,clientId: String,clientSecert : String ,grantType: String){
        self.serverUrl = serverUrl
        self.clientId = clientId
        self.clientSecret = clientSecert
        self.grantType = grantType
    }

}
