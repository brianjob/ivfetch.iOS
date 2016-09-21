//
//  SearchablePokemonCollectionViewController.swift
//  IVFetch
//
//  Created by Brian Barton on 8/29/16.
//  Copyright © 2016 Brian Barton. All rights reserved.
//

import UIKit

class SearchablePokemonCollectionViewController: UIViewController, UISearchControllerDelegate, UISearchResultsUpdating, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIPopoverPresentationControllerDelegate
{
    private let REUSE_IDENTIFIER = "PokemonCell"

    private let COLLECTION_VIEW_PADDING = CGFloat(10)
    private let TOOLBAR_PADDING = CGFloat(10)
    private let TOOL_BAR_HEIGHT = CGFloat(44)
    private let TOOL_BAR_TEXT_HEIGHT = CGFloat(20)
    private let TOOL_BAR_CHAR_WIDTH = 12
    private let ARROW_SIZE = CGFloat(12)
    private let CLOCK_SIZE = CGFloat(16)
    private let UP_ARROW_Y = CGFloat(1)
    private let DOWN_ARROW_Y = CGFloat(30)
    
    private var recentButton: UIBarButtonItem?
    private var oTdoButton: UIBarButtonItem?
    private var dTdoButton: UIBarButtonItem?
    private var idButton: UIBarButtonItem?
    private var cpButton: UIBarButtonItem?
    private var ivButton: UIBarButtonItem?

    private var searchController: UISearchController?
    
    var pokemonService: PokemonService? = nil
    var errorMessage: String? = nil

    var pokemons: [Pokemon] = [Pokemon]() {
        didSet {
            filterData()
        }
    }
    
    private var filteredPokemons = [Pokemon]() {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    private var currentSearchQuery: String? = nil
    
    var primarySortField: SortField? = nil
    
    var secondarySortField: SortField? = nil {
        didSet {
            drawSortArrow()
            applySort()
        }
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Actions
    
    @IBAction func refreshData(sender: UIBarButtonItem) {
        primarySortField = nil
        pokemons.removeAll()
        activityIndicator.startAnimating()
        pokemonService!.getInventory({
            self.activityIndicator.stopAnimating()
            self.pokemons = $0
            print("data refreshed")
            },
            errorCallback: {_ in
                self.activityIndicator.stopAnimating()
                print("error refreshing data")
        })
        setupToolbar()
    }
    
    
    //MARK: Setup & Teardown
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        print("collection view did load")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.definesPresentationContext = true // hide search bar on segue
        
        //setup the search controller
        searchController = ({
            let searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.hidesNavigationBarDuringPresentation = true
            searchController.dimsBackgroundDuringPresentation = false
            
            //setup the search bar
            searchController.searchBar.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
            self.searchBarContainer?.addSubview(searchController.searchBar)
            searchController.searchBar.sizeToFit()
            
            return searchController
        })()
        
        // setup the toolbar
        setupToolbar()
        
        // setup collection view
        collectionView!.contentInset = UIEdgeInsets(top: COLLECTION_VIEW_PADDING,
                                                    left: COLLECTION_VIEW_PADDING,
                                                    bottom: COLLECTION_VIEW_PADDING
                                                        + CGFloat(toolbar?.frame.height ?? 0),
                                                    right: COLLECTION_VIEW_PADDING)

        activityIndicator.hidesWhenStopped = true
    }
    
    
    //MARK: Search

    private func searchString(string: String, searchTerm:String) -> Bool {
        return string.lowercaseString.containsString(
            searchTerm.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).lowercaseString
        )
    }
    
    private func searchPokemon(pokemon: Pokemon, searchTerm: String) -> Bool {
        return searchString(pokemon.nickname ?? "", searchTerm: searchTerm) ||
               searchString(pokemon.species, searchTerm: searchTerm) ||
               searchString(pokemon.fastMoveName, searchTerm: searchTerm) ||
               searchString(pokemon.specialMoveName, searchTerm: searchTerm )
    }
    
    private func searchIsEmpty() -> Bool {
        if let searchTerm = self.searchController?.searchBar.text {
            return searchTerm.isEmpty
        }
        return true
    }
    
    private func filterData() {
        if (searchIsEmpty()) {
            filteredPokemons = pokemons
        } else {
            filteredPokemons = pokemons.filter({ (pokemon) -> Bool in
                let searchTerm = self.searchController!.searchBar.text!
                return searchPokemon(pokemon, searchTerm: searchTerm)
            })
        }
    }
    
    // MARK: Toolbar
    
    private func drawSortArrow() {
        setupToolbar() // clear up/down arrows
        
        guard let sortField = primarySortField
            else { return }
        
        var buttonToAddArrow: UIBarButtonItem = recentButton!
        var sortAscending: Bool = true
        
        // tint button for sorted field
        switch sortField {
        case .Recent:
            buttonToAddArrow = recentButton!
            sortAscending = recentSortAscending
        case .OTdo:
            buttonToAddArrow = oTdoButton!
            sortAscending = offTdoSortAscending
        case .DTdo:
            buttonToAddArrow = dTdoButton!
            sortAscending = defTdoSortAscending
        case .Id:
            buttonToAddArrow = idButton!
            sortAscending = speciesSortAscending
        case .Cp:
            buttonToAddArrow = cpButton!
            sortAscending = cpSortAscending
        case .Iv:
            buttonToAddArrow = ivButton!
            sortAscending = ivSortAscending
        }
        
        // add arrows
        if sortAscending {
            buttonToAddArrow.customView?.addSubview(getUpArrowSubview(buttonToAddArrow.customView!.frame.width))
        } else {
            buttonToAddArrow.customView?.addSubview(getDownArrowSubview(buttonToAddArrow.customView!.frame.width))
        }
    }
    
    private func setupToolbar() {
        let oTdoButtonText = "Off"
        let dTdoButtonText = "Def"
        let idButtonText = "#"
        let cpButtonText = "CP"
        let ivButtonText = "IV"
        
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        fixedSpace.width = TOOLBAR_PADDING
        
        recentButton = makeImageBarButtonItem("clock-32", width: CLOCK_SIZE)
        oTdoButton = makeTextBarButtonItem(oTdoButtonText)
        dTdoButton = makeTextBarButtonItem(dTdoButtonText)
        idButton = makeTextBarButtonItem(idButtonText)
        cpButton = makeTextBarButtonItem(cpButtonText)
        ivButton = makeTextBarButtonItem(ivButtonText)

        toolbar?.items = [
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace , target: nil, action: nil),
            recentButton!, fixedSpace, oTdoButton!, fixedSpace, dTdoButton!, fixedSpace, idButton!,
            fixedSpace, cpButton!, fixedSpace, ivButton!, fixedSpace
        ]
    }
    
    private func makeBarButtonItem(contentView: UIView) -> UIBarButtonItem {
        let button = UIButton(type: .Custom)
        button.frame = CGRectMake(0, 0, contentView.frame.width, TOOL_BAR_HEIGHT)
        button.addTarget(self, action: #selector(applyPrimarySort), forControlEvents: .TouchUpInside)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(showSecondarySortModal))
        button.addGestureRecognizer(longPress)

        button.tintColor = self.view.tintColor
        
        button.addSubview(contentView)
        
        let buttonItem = UIBarButtonItem(customView: button)

        return buttonItem
    }
    
    private func makeTextBarButtonItem(title: String) -> UIBarButtonItem {
        let width = CGFloat(title.characters.count * TOOL_BAR_CHAR_WIDTH)
        let label = UILabel(frame: CGRectMake(0, (TOOL_BAR_HEIGHT - TOOL_BAR_TEXT_HEIGHT) / 2, width, TOOL_BAR_TEXT_HEIGHT))
        label.text = title
        label.textColor = self.view.tintColor
        label.textAlignment = .Center
        label.backgroundColor = UIColor.clearColor()
        
        return makeBarButtonItem(label)
    }
    
    private func makeImageBarButtonItem(imageName: String, width: CGFloat) -> UIBarButtonItem {
        let clock = UIImageView(frame: CGRectMake(0, (TOOL_BAR_HEIGHT -  width) / 2, width, width))
        clock.image = UIImage(named: imageName)?.imageWithRenderingMode(.AlwaysTemplate)
        
        return makeBarButtonItem(clock)
    }
    
    private func getDownArrowSubview(superViewWidth: CGFloat) -> UIView {
        let downArrow = UIImageView(frame: CGRectMake(superViewWidth / 2 - ARROW_SIZE / 2, DOWN_ARROW_Y, ARROW_SIZE, ARROW_SIZE))
        downArrow.image = UIImage(named: "down-arrow-24")?.imageWithRenderingMode(.AlwaysTemplate)
        return downArrow
    }
    
    private func getUpArrowSubview(superViewWidth: CGFloat) -> UIView {
        let upArrow = UIImageView(frame: CGRectMake(superViewWidth / 2 - ARROW_SIZE / 2, UP_ARROW_Y, ARROW_SIZE, ARROW_SIZE))
        upArrow.image = UIImage(named: "up-arrow-24")?.imageWithRenderingMode(.AlwaysTemplate)
        return upArrow
    }

    // MARK: Sorting
    
    @objc private func showSecondarySortModal(sender: UIGestureRecognizer) {
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("secondarySortPopover") as! SecondarySortController
        vc.searchablePokemonCollectionViewController = self
        vc.modalPresentationStyle = UIModalPresentationStyle.Popover
        vc.preferredContentSize = CGSize(width: 80, height: 150)
        let popover: UIPopoverPresentationController = vc.popoverPresentationController!
        
        popover.sourceView = toolbar
        popover.sourceRect = (sender.view?.frame)!
        popover.delegate = self
        presentViewController(vc, animated: true, completion:nil)
        setPrimarySortField(sender.view as! UIButton)
        vc.primarySortField = primarySortField
    }
    
    @objc private func applyPrimarySort(sender: UIButton) {
        setPrimarySortField(sender)
        drawSortArrow()
        applySort()
    }
    
    private func setPrimarySortField(sender: UIButton) {
        if sender == cpButton?.customView {
            primarySortField = .Cp
        } else if sender == idButton?.customView {
            primarySortField = .Id
        } else if sender == ivButton?.customView {
            primarySortField = .Iv
        } else if sender == oTdoButton?.customView {
            primarySortField = .OTdo
        } else if sender == dTdoButton?.customView {
            primarySortField = .DTdo
        } else if sender == recentButton?.customView {
            primarySortField = .Recent
        }
    }
    
    private func getSortFieldValue(sortField: SortField, pokemon: Pokemon) -> Double {
        switch sortField {
        case .Cp:
            return Double(pokemon.cp)
        case .Id:
            return Double(pokemon.pokemonId)
        case .Iv:
            return pokemon.ivPct
        case .OTdo:
            return Double(pokemon.offensiveTdo ?? 0)
        case .DTdo:
            return Double(pokemon.defensiveTdo ?? 0)
        case .Recent:
            return pokemon.timeCaught.timeIntervalSince1970
        }
    }
    
    private func getPrimarySortOrder(sortField: SortField) -> Bool {
        var sortOrder: Bool
        switch sortField {
        case .Cp:
            sortOrder = cpSortAscending
            cpSortAscending = !cpSortAscending
        case .Id:
            sortOrder = speciesSortAscending
            speciesSortAscending = !speciesSortAscending
        case .Iv:
            sortOrder = ivSortAscending
            ivSortAscending = !ivSortAscending
        case .OTdo:
            sortOrder = offTdoSortAscending
            offTdoSortAscending = !offTdoSortAscending
        case .DTdo:
            sortOrder = defTdoSortAscending
            defTdoSortAscending = !defTdoSortAscending
        case .Recent:
            sortOrder = recentSortAscending
            recentSortAscending = !recentSortAscending
        }
        
        return sortOrder
    }
    
    private func getSecondarySortOrder(sortField: SortField) -> Bool {
        switch sortField {
        case .Id:
            return true
        default:
            return false
        }
    }
    
    
    private func applySort() {
        if primarySortField == nil {
            return
        }
        
        let primarySortOrder = getPrimarySortOrder(primarySortField!)
        
        pokemons.sortInPlace() {
            let primarySortField1 = getSortFieldValue(primarySortField!, pokemon: $0)
            let primarySortField2 = getSortFieldValue(primarySortField!, pokemon: $1)
            if primarySortField1 < primarySortField2 {
                return primarySortOrder
            } else if primarySortField1 > primarySortField2 {
                return !primarySortOrder
            } else if secondarySortField != nil {
                let secondarySortOrder = getSecondarySortOrder(secondarySortField!)

                if getSortFieldValue(secondarySortField!, pokemon: $0) < getSortFieldValue(secondarySortField!, pokemon: $1) {
                    return secondarySortOrder
                } else {
                    return !secondarySortOrder
                }
            }
            
            return primarySortOrder
        }
    }
    
    private var recentSortAscending = false
    private var speciesSortAscending = true
    private var cpSortAscending = false
    private var ivSortAscending = false
    private var offTdoSortAscending = false
    private var defTdoSortAscending = false
    
    //MARK:UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterData()
        collectionView?.reloadData()
    }
    
    //MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredPokemons.count
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(REUSE_IDENTIFIER, forIndexPath: indexPath) as!
        PokemonSpriteCollectionViewCell

        let pokemon = filteredPokemons[indexPath.row]
        
        setupCellLabel(cell.topLabel)
        setupCellLabel(cell.bottomLabel)
        cell.pokemonId = pokemon.pokemonId
        cell.bottomLabel.text = pokemon.displayName
        
        if let sortField = primarySortField {
            switch sortField {
            case .OTdo:
                cell.topLabel.text = "\(pokemon.offensiveTdo ?? 0) oTDO"
            case .DTdo:
                cell.topLabel.text = "\(pokemon.defensiveTdo ?? 0) dTDO"
            case .Cp:
                cell.topLabel.text = "\(pokemon.cp) cp"
            case .Iv:
                cell.topLabel.text = "\(Int(round(pokemon.ivPct)))%"
            case .Recent:
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "MM/dd/yy"
                cell.topLabel.text = dateFormatter.stringFromDate(pokemon.timeCaught)
            case .Id:
                cell.topLabel.text = "\(pokemon.cp) cp"
            }
        } else {
            cell.topLabel.text = "\(pokemon.cp) cp"
        }
        
        let green = CGFloat(min(pokemon.ivPct / 50.0, 1.0))
        let red = CGFloat(min(-1.0 * pokemon.ivPct / 50.0 + 2.0, 1.0))

        cell.layer.borderColor = UIColor(red: red, green: green, blue: 0.0, alpha: 0.75).CGColor
        cell.layer.cornerRadius = 4
        cell.layer.borderWidth = 1.5

        return cell
    }
    
    // sets common attributes for labels within collection cell
    private func setupCellLabel(label: UILabel) {
        label.numberOfLines = 1
        label.minimumScaleFactor = 0.4
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .Center
    }
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView)
    {
        //dismiss the keyboard if the search results are scrolled
        searchController?.searchBar.resignFirstResponder()
    }
    
    // MARK: UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None // force ui popover
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let pokemonDetailViewController = segue.destinationViewController as? PokemonDetailViewController {
            
            if let selectedPokemonCell = sender as? PokemonSpriteCollectionViewCell {
                let indexPath = collectionView!.indexPathForCell(selectedPokemonCell)!
                let selectedPokemon = filteredPokemons[indexPath.row]
                pokemonDetailViewController.pokemon = selectedPokemon
                pokemonDetailViewController.title = selectedPokemon.displayName
                
                currentSearchQuery = searchController?.searchBar.text // save search query to repopulate on return
            }
        } else if let loginController = segue.destinationViewController as? LoginViewController {
            loginController.logout()
        }
        
        // hide the keyboard
        if ((searchController?.searchBar.isFirstResponder()) != nil) {
            searchController?.searchBar.resignFirstResponder()
        }
    }
}

