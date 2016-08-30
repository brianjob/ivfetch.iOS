//
//  LoginViewController.swift
//  IVFetch
//
//  Created by Brian Barton on 8/26/16.
//  Copyright © 2016 Brian Barton. All rights reserved.
//

import UIKit
import CoreLocation

class LoginViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {
    let COLLECTION_CONTROLLER_ID = "YourPokemonController"
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var pokemonService: PokemonService?
    
    // MARK: Outlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var locationRetryButton: UIButton!
    @IBOutlet weak var googleLoginButton: UIButton!
    @IBOutlet weak var ptcLoginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if location == nil {
            googleLoginButton.enabled = false // can't login without location
            ptcLoginButton.enabled = false
        }

        googleLoginButton.layer.cornerRadius = 6
        ptcLoginButton.layer.cornerRadius = 6
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        // setup location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        retryGetLocation()
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let firstLocation = locations.first {
            location = firstLocation
            print("location received: \(firstLocation.coordinate)")
            activityIndicator.stopAnimating()
            googleLoginButton.enabled = true
            ptcLoginButton.enabled = true
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
    
    @IBAction func googleLogin() {
        login(AuthService.Google)
    }

    @IBAction func ptcLogin() {
        login(AuthService.PTC)
    }

    
    private func login(authService: AuthService) {
        if passwordTextField.isFirstResponder() {
            passwordTextField.resignFirstResponder()
        } else if usernameTextField.isFirstResponder() {
            usernameTextField.resignFirstResponder()
        }
        
        if let username = usernameTextField.text, let password = passwordTextField.text, let location = self.location {
            
            activityIndicator.startAnimating()
            
            self.pokemonService = PokemonService(authService: authService, username: username, password: password, location: location)
            
            self.pokemonService!.getInventory({
                (pokemons: [Pokemon]) -> () in
                if let navigationController = self.storyboard?.instantiateViewControllerWithIdentifier(self.COLLECTION_CONTROLLER_ID)
                    as? UINavigationController {
                    if let collectionController = navigationController.topViewController as? SearchablePokemonCollectionViewController {
                        collectionController.pokemons = pokemons
                        collectionController.pokemonService = self.pokemonService
                        self.activityIndicator.stopAnimating()
                        self.presentViewController(navigationController, animated: true, completion: nil)
                    }
                }
                }, errorCallback: { (errorMessage: String) -> () in
                    self.activityIndicator.stopAnimating()
                    self.showErrorMessage(errorMessage)
                }
            )
        }
    }
    
    // logs the user out
    func logout() {
        pokemonService?.logout()
    }
}

