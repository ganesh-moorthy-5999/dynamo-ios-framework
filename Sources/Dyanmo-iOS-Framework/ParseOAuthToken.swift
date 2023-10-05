//
//  File.swift
//  
//
//  Created by Akashchellakumar on 10/09/20.
//

import Foundation

public struct ParseOAuthToken: Codable {
    
    public let access_token: String
    public let expires_in: Int
    public let refresh_token: String
    public let scope: String
    public let token_type: String
    
}
