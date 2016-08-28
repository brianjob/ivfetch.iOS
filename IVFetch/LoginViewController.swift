//
//  LoginViewController.swift
//  IVFetch
//
//  Created by Brian Barton on 8/26/16.
//  Copyright © 2016 Brian Barton. All rights reserved.
//

import UIKit
import CoreLocation

class LoginViewController: UIViewController, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var pokemonService: PokemonService?
    
    // MARK: Outlets
    @IBOutlet weak var authServiceSwitch: UISwitch!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.requestLocation() // TODO: add spinner to indicate location retrieval in progress
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let firstLocation = locations.first {
            location = firstLocation
        } else {
            print("No location received")
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error finding location: \(error.localizedDescription)")
        
        // TODO: add retry button and spinner
    }

    // MARK: Actions

    @IBAction func login() {
        let authService = authServiceSwitch.on ? AuthService.PTC : AuthService.Google
        
        if let username = usernameTextField.text, let password = passwordTextField.text, let location = self.location {
            self.pokemonService = PokemonService(authService: authService, username: username, password: password, location: location)
            let collectionController = self.storyboard!.instantiateViewControllerWithIdentifier("PokemonCollectionViewController") as! PokemonCollectionViewController
            let navigationController =
                self.storyboard!.instantiateViewControllerWithIdentifier("NavigationController") as!
                    UINavigationController
            collectionController.pokemonService = self.pokemonService
            self.pokemonService!.getInventory({(pokemons: [Pokemon]) -> () in
                self.presentViewController(navigationController, animated: true, completion: nil)
            })
        }
    }
    
    // logs the user out
    @IBAction func logout(sender: UIStoryboardSegue) {
        pokemonService?.logout()
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("LoginViewController prepare for segue")
        let authService = authServiceSwitch.on ? AuthService.PTC : AuthService.Google
        
        if let username = usernameTextField.text, let password = passwordTextField.text, let location = self.location {
            self.pokemonService = PokemonService(authService: authService, username: username, password: password, location: location)
            if let destinationViewController = segue.destinationViewController as? PokemonCollectionViewController {
                destinationViewController.pokemonService = pokemonService
                self.pokemonService!.getInventory({(pokemons: [Pokemon]) -> () in
                    destinationViewController.pokemons = pokemons
                })
            }
        }
    }
}

