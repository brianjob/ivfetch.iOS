//
//  Pokemon.swift
//  IVFetch
//
//  Created by Brian Barton on 8/26/16.
//  Copyright © 2016 Brian Barton. All rights reserved.
//

import Foundation
import CoreLocation
import PGoApi

class PokemonService: PGoAuthDelegate, PGoApiDelegate {
    // MARK: Constants
    let MAX_ALTITUDE: UInt32 = 200
    
    // MARK: Properties

    private var request = PGoApiRequest()
    private var location: CLLocation
    private var auth: PGoAuth?
    private var finalIntent: PGoApiIntent?
    private let authService: AuthService
    private let username: String
    private let password: String
    
    // MARK: Init
    
    init(authService: AuthService, username: String, password: String, location: CLLocation) {
        self.authService = authService
        self.username = username
        self.password = password
        self.location = location
    }
    
    private var getInventoryCallback: ([Pokemon]) -> () = {_ in }
    
    func getInventory(callback: ([Pokemon]) -> ()) {
        self.getInventoryCallback = callback
        self.finalIntent = .GetInventory
        
        if (assureAuthServiceLogin()) {
            makeNianticLogin()
        }
    }
    
    // logs the user out
    func logout() {
        auth = nil
    }
    
    // if already logged in to auth service return true
    // if not, login and return false
    private func assureAuthServiceLogin() -> Bool {
        if let auth = auth where auth.loggedIn {
            print("already logged in")
            return true
        }
        
        switch self.authService {
        case .Google:
            let googleAuth = GPSOAuth()
            googleAuth.delegate = self
            googleAuth.login(withUsername: username, withPassword: password)
            self.auth = googleAuth
        case .PTC:
            let ptcAuth = PtcOAuth()
            ptcAuth.delegate = self
            ptcAuth.login(withUsername: username, withPassword: password)
            self.auth = ptcAuth
        }
        return false
    }
    
    // set location and make niantic login request
    private func makeNianticLogin() {
        self.request = PGoApiRequest(auth: auth)
        self.request.setLocation(self.location.coordinate.latitude,
                                 longitude: location.coordinate.longitude,
                                 altitude: Double(arc4random_uniform(MAX_ALTITUDE) + 1))
        self.request.simulateAppStart()
        self.request.makeRequest(.Login, delegate: self)
    }
    
    
    // MARK: PGoAuthDelegate
    
    // callback function when auth service login is successful
    func didReceiveAuth() {
        print("oauth authentication complete")
        makeNianticLogin()
    }
    
    // callback function when auth service login not successful
    func didNotReceiveAuth() {
        print("authorization failed")
    }
    
    // MARK: PgoApiDelegate
    
    // dictionary of PGoApiIntent and its associated request method
    lazy private var finalIntentActionDict: [PGoApiIntent: () -> ()]  = [
        .GetInventory: { self.request.getInventory() }
    ]
    
    // callback for api request
    // only getInventory currently supported
    func didReceiveApiResponse(intent: PGoApiIntent, response: PGoApiResponse) {
        print ("received api response")
        switch intent {
        case .Login:
            finalIntentActionDict[finalIntent!]!()
            request.makeRequest(finalIntent!, delegate: self)
        case .GetInventory:
            handleGetInventory(response)
        default: break
        }
    }
    
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?) {
        print("API Error: \(statusCode)")
    }
    
    // MARK: API response handlers
    
    private func handleGetInventory(response: PGoApiResponse) {
        var pokemons = [Pokemon]()
        
        if (response.subresponses.count > 0) {
            let inventory = response.subresponses[0] as! Pogoprotos.Networking.Responses.GetInventoryResponse
            
            for pokemon in inventory.inventoryDelta.inventoryItems
                .filter({ $0.hasInventoryItemData && $0.inventoryItemData.hasPokemonData && !$0.inventoryItemData.pokemonData.isEgg })
                .map({ $0.inventoryItemData.pokemonData }) {
                    print("adding pokemon")
                    pokemons += [Pokemon(
                        nickname: pokemon.nickname,
                        species: pokemon.pokemonId.toString(),
                        pokemonId: Int(pokemon.pokemonId.rawValue),
                        isFavorite: pokemon.favorite == 1,
                        height: Double(pokemon.heightM),
                        weight: Double(pokemon.weightKg),
                        cp: Int(pokemon.cp),
                        hp: Int(pokemon.stamina),
                        maxHp: Int(pokemon.staminaMax),
                        move1: pokemon.move1,
                        move2: pokemon.move2,
                        individualAttack: Int(pokemon.individualAttack),
                        individualDefense: Int(pokemon.individualDefense),
                        individualStamina: Int(pokemon.individualStamina),
                        battlesAttacked: Int(pokemon.battlesAttacked),
                        battlesDefended: Int(pokemon.hasBattlesDefended),
                        timeCaught: NSDate(timeIntervalSince1970: Double(pokemon.creationTimeMs) / 1000.0))]
            }
            
            getInventoryCallback(pokemons)
        } else {
            print("get inventory returned empty response")
        }
    }
}

enum AuthService {
    case Google
    case PTC
}

struct Pokemon {
    let nickname: String?
    let species: String
    let pokemonId: Int
    let isFavorite: Bool
    
    let height: Double
    let weight: Double
    
    let cp: Int
    let hp: Int
    let maxHp: Int
    
    let move1: PGoApi.Pogoprotos.Enums.PokemonMove
    let move2: PGoApi.Pogoprotos.Enums.PokemonMove
    
    let individualAttack: Int
    let individualDefense: Int
    let individualStamina: Int
    
    let battlesAttacked: Int
    let battlesDefended: Int
    
    let timeCaught: NSDate
    
    var iVPct: Double {
        return Double(individualAttack + individualStamina + individualDefense) / 45
    }
    
    var displayName: String {
        return nickname ?? species
    }
}