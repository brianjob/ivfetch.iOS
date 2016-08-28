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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var locationRetryButton: UIButton!
    @IBOutlet weak var loginButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if location == nil {
            loginButton.enabled = false // can't login without location
        }
        
        // setup location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        retryGetLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let firstLocation = locations.first {
            location = firstLocation
            activityIndicator.stopAnimating()
            loginButton.enabled = true
        } else {
            print("No location received")
            notifyOfErrorFindingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error finding location: \(error.localizedDescription)")
        notifyOfErrorFindingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            retryGetLocation()
        }
    }
    
    private func showErrorMessage(message: String) {
        messageLabel.text = message
        messageLabel.textColor = UIColor.redColor()
        messageLabel.numberOfLines = 1
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.hidden = false
    }
    
    private func notifyOfErrorFindingLocation() {
        showErrorMessage("Could not determine location")
        locationRetryButton.hidden = false
        activityIndicator.stopAnimating()
    }

    // MARK: Actions

    // attempts to get location
    @IBAction func retryGetLocation() {
        messageLabel.hidden = true
        locationRetryButton.hidden = true
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        switch authorizationStatus {
        case .Denied, .NotDetermined:
            showErrorMessage("Authorize location services to continue")
            locationManager.requestWhenInUseAuthorization()
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            activityIndicator.startAnimating()
            locationManager.requestLocation()
        case .Restricted:
            showErrorMessage("Your device does not allow location services")
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
                    }, errorCallback: { (errorMessage: String) -> () in
                       destinationViewController.errorMessage = errorMessage
                })
            }
        }
    }
}

