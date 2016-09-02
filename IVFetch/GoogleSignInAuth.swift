//
//  GoogleSignInAuth.swift
//  IVFetch
//
//  Created by Brian Barton on 8/31/16.
//  Copyright © 2016 Brian Barton. All rights reserved.
//

import Foundation
import PGoApi
import Alamofire

class GoogleSignInAuth : PGoAuth {
    static internal let LOGIN_URL = "https://accounts.google.com/o/oauth2/auth?client_id=848232511240-73ri3t7plvk96pj4f85uj8otdat2alem.apps.googleusercontent.com&redirect_uri=urn%3Aietf%3Awg%3Aoauth%3A2.0%3Aoob&response_type=code&scope=openid%20email%20https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email"
    private let OAUTH_TOKEN_ENDPOINT = "https://www.googleapis.com/oauth2/v4/token"
    private let SECRET = "NCjF1TLi2CcY6t5mt0ZveuL7"
    private let CLIENT_ID = "848232511240-73ri3t7plvk96pj4f85uj8otdat2alem.apps.googleusercontent.com"

    
    var email: String!
    var password: String!
    var token: String?
    var accessToken: String?
    var expires: Int?
    var expired: Bool = false
    var loggedIn: Bool = false
    var delegate: PGoAuthDelegate?
    var authType: PGoAuthType = .Google
    var endpoint: String = PGoEndpoint.Rpc
    var authToken: Pogoprotos.Networking.Envelopes.AuthTicket?
    var manager: Manager
    var banned: Bool = false
    
    init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        manager = Alamofire.Manager(configuration: configuration)
    }
    
    // username is not used and password is oauth code user receives after approving access
    func login(withUsername username: String, withPassword password: String) {
        Alamofire.request(.POST, OAUTH_TOKEN_ENDPOINT, parameters: [
            "code": password,
            "client_id": CLIENT_ID,
            "client_secret": SECRET,
            "grant_type": "authorization_code",
            "scope": "openid email https://www.googleapis.com/auth/userinfo.email",
            "redirect_uri": "urn:ietf:wg:oauth:2.0:oob"
            ]).validate().responseJSON { response in
                switch response.result {
                case .Success(let data):
                    if let json = data as? NSDictionary, let token = json["id_token"] as? String {
                        self.accessToken = token
                        self.loggedIn = true
                        self.delegate?.didReceiveAuth()
                    } else {
                        self.delegate?.didNotReceiveAuth()
                    }
                case .Failure:
                    self.delegate?.didNotReceiveAuth()
                }
        }
    }
}