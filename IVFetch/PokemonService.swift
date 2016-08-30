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

let MOVESET_FILENAME = "moveSets.csv"

class PokemonService: PGoAuthDelegate, PGoApiDelegate {
    // MARK: Constants
    let MAX_ALTITUDE: UInt32 = 200
    let API_ERROR_MESSAGE = "An API Error Occured"
    let AUTH_ERROR_MESSAGE = "Authentication Failed"
    let GET_INVENTORY_ERROR = "Could Not Retrieve Inventory"
    
    // MARK: Properties

    private var request = PGoApiRequest()
    private var location: CLLocation
    private var auth: PGoAuth?
    private var finalIntent: PGoApiIntent?
    private let authService: AuthService
    private let username: String
    private let password: String
    private let moveSets: [MoveSet]
    
    // MARK: Init
    
    init(authService: AuthService, username: String, password: String, location: CLLocation) {
        self.authService = authService
        self.username = username
        self.password = password
        self.location = location
        self.moveSets = PokemonService.getMoveSets()
    }
    
    private var getInventoryCallback: ([Pokemon]) -> () = {_ in }
    private var errorCallback: (String) -> () = {_ in }
    
    func getInventory(successCallback: ([Pokemon]) -> (), errorCallback: (String) -> ()) {
        self.getInventoryCallback = successCallback
        self.errorCallback = errorCallback
        
        self.finalIntent = .GetInventory
        
        if (assureAuthServiceLogin()) {
            makeNianticLogin()
        }
    }
    
    // logs the user out
    func logout() {
        print("logging out")
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
        errorCallback(AUTH_ERROR_MESSAGE)
        print("authentication failed")
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
        errorCallback(API_ERROR_MESSAGE)
        print("API Error: \(statusCode)")
    }
    
    // MARK: API response handlers
    
    private func handleGetInventory(response: PGoApiResponse) {
        var pokemons = [Pokemon]()
        
        if (response.subresponses.count > 0) {
            let inventory = response.subresponses[0] as! Pogoprotos.Networking.Responses.GetInventoryResponse
            
            if (inventory.hasInventoryDelta) {
                for pokemon in inventory.inventoryDelta.inventoryItems
                    .filter({ $0.hasInventoryItemData && $0.inventoryItemData.hasPokemonData && !$0.inventoryItemData.pokemonData.isEgg })
                    .map({ $0.inventoryItemData.pokemonData }) {
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
                            moveSet: lookupMoveSet(Int(pokemon.pokemonId.rawValue), move1: pokemon.move1, move2: pokemon.move2),
                            individualAttack: Int(pokemon.individualAttack),
                            individualDefense: Int(pokemon.individualDefense),
                            individualStamina: Int(pokemon.individualStamina),
                            battlesAttacked: Int(pokemon.battlesAttacked),
                            battlesDefended: Int(pokemon.hasBattlesDefended),
                            timeCaught: NSDate(timeIntervalSince1970: Double(pokemon.creationTimeMs) / 1000.0))]
                }
                
                getInventoryCallback(pokemons)
            } else {
                errorCallback(GET_INVENTORY_ERROR)
                print("no inventory delta")
            }
        } else {
            errorCallback(GET_INVENTORY_ERROR)
            print("get inventory returned empty response")
        }
    }
    
    // returns nil if no moveset found
    private func lookupMoveSet(pokemonId: Int,
                               move1: PGoApi.Pogoprotos.Enums.PokemonMove,
                               move2: PGoApi.Pogoprotos.Enums.PokemonMove) -> MoveSet {
        var results = moveSets.filter(
            { $0.pokemonId == pokemonId &&
              $0.fastMoveName == moveToString(move1) &&
              $0.specialMoveName == moveToString(move2)
            })
        
        if results.count != 1 {
            print("unexptected result: [\(pokemonId)] \(move1.toString()), \(move2.toString())")
            return MoveSet(moveSetId: nil,
                           pokemonId: pokemonId,
                           fastMoveName: moveToString(move1),
                           specialMoveName: moveToString(move2),
                           isSpecialMoveUseless: nil,
                           offensivePctOfTopMoveSet: nil,
                           defensivePctOfTopMoveSet: nil,
                           offensiveTDO: nil,
                           defensiveTDO: nil)
        }
        
        return results[0]
    }
    
    private func moveToString(move: PGoApi.Pogoprotos.Enums.PokemonMove) -> String {
        return move.toString()
            .capitalizedString
            .stringByReplacingOccurrencesOfString("_", withString: " ")
            .stringByReplacingOccurrencesOfString(" Fast", withString: "")
    }
    
    private class func getMoveSets() -> [MoveSet] {
        let moveSetFile = NSDataAsset(name: MOVESET_FILENAME)?.data
        let moveSetString = String(data: moveSetFile!, encoding: NSUTF8StringEncoding)!
        let moveSetTable = moveSetString.componentsSeparatedByString("\r").map({ $0.componentsSeparatedByString(",")})
        
        var moveSetArray = [MoveSet]()
        
        for moveSetRow in moveSetTable[1..<moveSetTable.count] {
            moveSetArray.append(MoveSet(
                moveSetId: Int(moveSetRow[0])!,
                pokemonId: Int(moveSetRow[1])!,
                fastMoveName: moveSetRow[3],
                specialMoveName: moveSetRow[4],
                isSpecialMoveUseless: moveSetRow[5] != "",
                offensivePctOfTopMoveSet: moveSetRow[6],
                defensivePctOfTopMoveSet: moveSetRow[7],
                offensiveTDO: Int(moveSetRow[8])!,
                defensiveTDO: Int(moveSetRow[9])!))
        }
        
        return moveSetArray
    }
}

enum AuthService {
    case Google
    case PTC
}

struct Pokemon {
    let nickname: String?
    let species: String
    var speciesPretty: String {
        return species
            .stringByReplacingOccurrencesOfString("_MALE", withString: " ♂")
            .stringByReplacingOccurrencesOfString("_FEMALE", withString: " ♀")
            .capitalizedString
    }
    let pokemonId: Int
    let isFavorite: Bool
    
    let height: Double
    let weight: Double
    
    let cp: Int
    let hp: Int
    let maxHp: Int
    
    let moveSet: MoveSet
    
    let individualAttack: Int
    let individualDefense: Int
    let individualStamina: Int
    
    let battlesAttacked: Int
    let battlesDefended: Int
    
    let timeCaught: NSDate
    
    var ivPct: Double {
        return Double(individualAttack + individualStamina + individualDefense) / 45 * 100
    }
    
    var displayName: String {
        return nickname == nil || (nickname?.isEmpty)! ? speciesPretty : nickname!
    }
    
    private func formatMove(move: Pogoprotos.Enums.PokemonMove) -> String {
        return move.toString()
            .capitalizedString
            .stringByReplacingOccurrencesOfString("_", withString: " ")
    }
}

struct MoveSet {
    let moveSetId: Int?
    let pokemonId: Int
    let fastMoveName: String
    let specialMoveName: String
    let isSpecialMoveUseless: Bool?
    let offensivePctOfTopMoveSet: String?
    let defensivePctOfTopMoveSet: String?
    let offensiveTDO: Int?
    let defensiveTDO: Int?
}