//
//  Pokemon.swift
//  IVFetch
//
//  Created by Brian Barton on 8/26/16.
//  Copyright © 2016 Brian Barton. All rights reserved.
//

import Foundation
import PGoApi
import PokeGuru

let MOVESET_FILENAME = "moveSets.csv"

class PokemonService: PGoAuthDelegate, PGoApiDelegate {
    // MARK: Constants
    let MAX_ALTITUDE: UInt32 = 200
    let API_ERROR_MESSAGE = "An API Error Occured"
    let AUTH_ERROR_MESSAGE = "Authentication Failed"
    let GET_INVENTORY_ERROR = "Could Not Retrieve Inventory"
    
    // MARK: Properties

    private var request: PGoApiRequest? = nil
    private var auth: PGoAuth?
    private var finalIntent: PGoApiIntent?
    private let authService: AuthService
    private let username: String?
    private let password: String?

    
    // MARK: Init
    
    init(authService: AuthService, username: String, password: String) {
        self.authService = authService
        self.username = username
        self.password = password
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
        
        switch authService {
        case .Google:
            let gpsOAuth = GPSOAuth()
            gpsOAuth.login(withToken: password!)
            auth = gpsOAuth
        case .PTC:
            auth = PtcOAuth()
            auth!.login(withUsername: username!, withPassword: password!)
        }
        auth!.delegate = self
        return false
    }
    
    // set location and make niantic login request
    private func makeNianticLogin() {
        request = PGoApiRequest(auth: auth!)
        request!.simulateAppStart()
        request!.makeRequest(.Login, delegate: self)

        if auth!.expired {
            auth?.authToken = nil
            auth?.login(withUsername: username!, withPassword: password!)
        }
    }
    
    
    // MARK: PGoAuthDelegate
    
    // callback function when auth service login is successful
    func didReceiveAuth() {
        print("oauth authentication complete")
        auth?.expired = false
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
        .GetInventory: { self.request!.getInventory() }
    ]
    
    // callback for api request
    // only getInventory currently supported
    func didReceiveApiResponse(intent: PGoApiIntent, response: PGoApiResponse) {
        print ("received api response")
        switch intent {
        case .Login:
            finalIntentActionDict[finalIntent!]!()
            request!.makeRequest(finalIntent!, delegate: self)
        case .GetInventory:
            handleGetInventory(response)
        default: break
        }
    }
    
    func didReceiveApiError(intent: PGoApiIntent, statusCode: Int?) {
        errorCallback(API_ERROR_MESSAGE)
        print("API Error: \(statusCode)")
    }
    
    func didReceiveApiException(intent: PGoApiIntent, exception: PGoApiExceptions) {
        print("API Exception: \(exception)")
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

                        let pokeGuru = PokeGuru(pokemonId: Int(pokemon.pokemonId.rawValue), fastMoveId: Int(pokemon.move1.rawValue),
                                                specialMoveId: Int(pokemon.move2.rawValue), cp: Int(pokemon.cp),
                                                individualAttack: Int(pokemon.individualAttack), individualDefense: Int(pokemon.individualDefense),
                                                individualStamina: Int(pokemon.individualStamina))
                        
                        pokemons += [Pokemon(
                            nickname: pokemon.nickname,
                            species: pokemon.pokemonId.toString(),
                            pokemonId: Int(pokemon.pokemonId.rawValue),
                            isFavorite: pokemon.favorite == 1,
                            height: Double(pokemon.heightM),
                            weight: Double(pokemon.weightKg),
                            type: pokeGuru.pokemon.types.map { $0.name }.joinWithSeparator(" / "),
                            attack: Int(round(pokeGuru.attack)),
                            defense: Int(round(pokeGuru.defense)),
                            cp: Int(pokemon.cp),
                            hp: Int(pokemon.stamina),
                            eHp: Int(round(pokeGuru.eHp)),
                            maxHp: Int(pokemon.staminaMax),
                            fastMoveName: pokeGuru.fastMove.name,
                            fastMoveType: pokeGuru.fastMove.type.name,
                            specialMoveName: pokeGuru.specialMove.name,
                            specialMoveType: pokeGuru.specialMove.type.name,
                            isSpecialMoveUseless: pokeGuru.uselessSpecial,
                            fastDps: pokeGuru.dpsFast,
                            comboDps: pokeGuru.dpsCombo,
                            defensiveDps: pokeGuru.dpsDefense,
                            offensiveEfficiency: pokeGuru.offensiveEfficiency * 100,
                            defensiveEfficiency: pokeGuru.defensiveEfficiency * 100,
                            offensiveTdo: Int(round(pokeGuru.tdoOffense)),
                            defensiveTdo: Int(round(pokeGuru.tdoDefense)),
                            individualAttack: Int(pokemon.individualAttack),
                            individualDefense: Int(pokemon.individualDefense),
                            individualStamina: Int(pokemon.individualStamina),
                            battles: Int(pokemon.battlesAttacked) + Int(pokemon.battlesDefended),
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
    
    private func moveToString(move: PGoApi.Pogoprotos.Enums.PokemonMove) -> String {
        return move.toString()
            .capitalizedString
            .stringByReplacingOccurrencesOfString("_", withString: " ")
            .stringByReplacingOccurrencesOfString(" Fast", withString: "")
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
    
    let type: String
    
    let attack: Int
    let defense: Int
    let cp: Int
    let hp: Int
    let eHp: Int
    let maxHp: Int
    
    let fastMoveName: String
    let fastMoveType: String
    let specialMoveName: String
    let specialMoveType: String
    let isSpecialMoveUseless: Bool?
    let fastDps: Double?
    let comboDps: Double?
    let defensiveDps: Double?
    let offensiveEfficiency: Double?
    let defensiveEfficiency: Double?
    let offensiveTdo: Int?
    let defensiveTdo: Int?
    
    let individualAttack: Int
    let individualDefense: Int
    let individualStamina: Int
    
    let battles: Int
    
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
