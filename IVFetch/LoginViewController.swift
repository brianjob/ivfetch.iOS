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
    let PTC_LOGIN_BUTTON_TEXT = "Login with PTC"
    let PTC_USERNAME_PLACEHOLDER = "ptc username"
    let PTC_PASSWORD_PLACEHOLDER = "password"
    let PTC_SWITCH_AUTH_BUTTON_TEXT = "Switch to Google"
    let GOOGLE_LOGIN_BUTTON_TEXT = "Login with Google"
    let GOOGLE_LOGIN_BUTTON_COLOR = UIColor(colorLiteralRed: 0, green: 128/255.0, blue: 1, alpha: 1)
    let GOOGLE_PASSWORD_PLACEHOLDER = "paste login code here"
    let GOOGLE_SWITCH_AUTH_BUTTON_TEXT = "Switch to PTC"
    
    let locationManager = CLLocationManager()
    
    var originalLoginButtonColor: UIColor? = nil
    
    var location: CLLocation?
    var pokemonService: PokemonService?
    var useGoogleAuth = false
    
    // MARK: Outlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var locationRetryButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var switchAuthButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if location == nil {
            loginButton.enabled = false // can't login without location
        }
        
        originalLoginButtonColor = loginButton.backgroundColor
        loginButton.layer.cornerRadius = 6
        passwordTextField.secureTextEntry = true
        
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        setupPtcLogin()
        
        // setup location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
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

    // toggles auth service between google and ptc
    @IBAction func switchAuthService(sender: UIButton) {
        useGoogleAuth = !useGoogleAuth
        passwordTextField.text = ""
        
        if (useGoogleAuth) {
            setupGoogleLogin()
        } else {
            setupPtcLogin()
        }
    }
    
    private func openAuthPage() {
        UIApplication.sharedApplication().openURL(NSURL(string: GoogleSignInAuth.LOGIN_URL)!)
    }
    
    private func setupGoogleLogin() {
        usernameTextField.hidden = true
        passwordTextField.placeholder = GOOGLE_PASSWORD_PLACEHOLDER
        passwordTextField.secureTextEntry = false
        loginButton.setTitle(GOOGLE_LOGIN_BUTTON_TEXT, forState: .Normal)
        loginButton.backgroundColor = GOOGLE_LOGIN_BUTTON_COLOR
        switchAuthButton.setTitle(GOOGLE_SWITCH_AUTH_BUTTON_TEXT, forState: .Normal)
        openAuthPage()
    }
    
    private func setupPtcLogin() {
        usernameTextField.hidden = false
        passwordTextField.placeholder = PTC_PASSWORD_PLACEHOLDER
        usernameTextField.placeholder = PTC_USERNAME_PLACEHOLDER
        passwordTextField.secureTextEntry = true
        loginButton.setTitle(PTC_LOGIN_BUTTON_TEXT, forState: .Normal)
        loginButton.backgroundColor = originalLoginButtonColor
        switchAuthButton.setTitle(PTC_SWITCH_AUTH_BUTTON_TEXT, forState: .Normal)
    }
    
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
    
    @IBAction func loginButtonPressed() {
        if (useGoogleAuth) {
            login(AuthService.Google)
        } else {
            login(AuthService.PTC)
        }
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

