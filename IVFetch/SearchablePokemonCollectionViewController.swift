//
//  SearchablePokemonCollectionViewController.swift
//  IVFetch
//
//  Created by Brian Barton on 8/29/16.
//  Copyright © 2016 Brian Barton. All rights reserved.
//

import UIKit

class SearchablePokemonCollectionViewController: UIViewController, UISearchControllerDelegate, UISearchResultsUpdating, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
{
    private let REUSE_IDENTIFIER = "PokemonCell"

    private let COLLECTION_VIEW_PADDING = CGFloat(10)
    private let TOOLBAR_PADDING = CGFloat(10)
    private let TOOL_BAR_HEIGHT = CGFloat(44)
    private let TOOL_BAR_TEXT_HEIGHT = CGFloat(20)
    //    private let TOOL_BAR_TEXT_WIDTH = CGFloat(31)
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
    
    var sortField: SortField? = nil {
        didSet {
            applySortArrow()
        }
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Actions
    
    @IBAction func refreshData(sender: UIBarButtonItem) {
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
    
    private func applySortArrow() {
        setupToolbar() // clear up/down arrows
        
        var buttonToAddArrow: UIBarButtonItem = recentButton!
        var sortAscending: Bool = true
        
        // tint button for sorted field
        switch sortField! {
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
        default:
            break
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
        
        recentButton = makeImageBarButtonItem("clock-32", action: #selector(sortRecent), width: CLOCK_SIZE)
        oTdoButton = makeTextBarButtonItem(oTdoButtonText, action: #selector(sortOffTdo))
        dTdoButton = makeTextBarButtonItem(dTdoButtonText, action: #selector(sortDefTdo))
        idButton = makeTextBarButtonItem(idButtonText, action: #selector(sortSpecies))
        cpButton = makeTextBarButtonItem(cpButtonText, action: #selector(sortCp))
        ivButton = makeTextBarButtonItem(ivButtonText, action: #selector(sortIv))

        toolbar?.items = [
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace , target: nil, action: nil),
            recentButton!, fixedSpace, oTdoButton!, fixedSpace, dTdoButton!, fixedSpace, idButton!,
            fixedSpace, cpButton!, fixedSpace, ivButton!, fixedSpace
        ]
    }
    
    private func makeBarButtonItem(contentView: UIView, action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .Custom)
        button.frame = CGRectMake(0, 0, contentView.frame.width, TOOL_BAR_HEIGHT)
        button.addTarget(self, action: action, forControlEvents: .TouchUpInside)
        button.tintColor = self.view.tintColor
        
        button.addSubview(contentView)
        
        let buttonItem = UIBarButtonItem(customView: button)

        return buttonItem
    }
    
    private func makeTextBarButtonItem(title: String, action: Selector) -> UIBarButtonItem {
        let width = CGFloat(title.characters.count * TOOL_BAR_CHAR_WIDTH)
        let label = UILabel(frame: CGRectMake(0, (TOOL_BAR_HEIGHT - TOOL_BAR_TEXT_HEIGHT) / 2, width, TOOL_BAR_TEXT_HEIGHT))
        label.text = title
        label.textColor = self.view.tintColor
        label.textAlignment = .Center
        label.backgroundColor = UIColor.clearColor()
        
        return makeBarButtonItem(label, action: action)
    }
    
    private func makeImageBarButtonItem(imageName: String, action: Selector, width: CGFloat) -> UIBarButtonItem {
        let clock = UIImageView(frame: CGRectMake(0, (TOOL_BAR_HEIGHT -  width) / 2, width, width))
        clock.image = UIImage(named: imageName)?.imageWithRenderingMode(.AlwaysTemplate)
        
        return makeBarButtonItem(clock, action: action)
    }
    
    private func makeRecentButton(action: Selector) -> UIBarButtonItem {
        return makeImageBarButtonItem("clock-32", action: action, width: CLOCK_SIZE)
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
    
    private var recentSortAscending = false
    @objc private func sortRecent() {
        filteredPokemons.sortInPlace({ applySortOrder($0.timeCaught < $1.timeCaught, sortAscending: recentSortAscending) })
        sortField = .Recent
        recentSortAscending = !recentSortAscending
    }
    private var nameSortAscending = true
    @objc private func sortName() {
        filteredPokemons.sortInPlace({ applySortOrder($0.displayName.lowercaseString < $1.displayName.lowercaseString, sortAscending: nameSortAscending) })
        sortField = .Name
        nameSortAscending = !nameSortAscending
    }
    private var speciesSortAscending = true
    @objc private func sortSpecies() {
        filteredPokemons.sortInPlace({ applySortOrder($0.pokemonId < $1.pokemonId, sortAscending: speciesSortAscending) })
        sortField = .Id
        speciesSortAscending = !speciesSortAscending
    }
    private var cpSortAscending = false
    @objc private func sortCp() {
        filteredPokemons.sortInPlace({ applySortOrder($0.cp < $1.cp, sortAscending: cpSortAscending)})
        sortField = .Cp
        cpSortAscending = !cpSortAscending
    }
    private var ivSortAscending = false
    @objc private func sortIv() {
        filteredPokemons.sortInPlace({ applySortOrder($0.ivPct < $1.ivPct, sortAscending: ivSortAscending) })
        sortField = .Iv
        ivSortAscending = !ivSortAscending
    }
    private var offTdoSortAscending = false
    @objc private func sortOffTdo() {
        filteredPokemons.sortInPlace({ applySortOrder(($0.offensiveTdo ?? 0) < ($1.offensiveTdo ?? 0), sortAscending: offTdoSortAscending) })
        sortField = .OTdo
        offTdoSortAscending = !offTdoSortAscending
    }
    private var defTdoSortAscending = false
    @objc private func sortDefTdo() {
        filteredPokemons.sortInPlace({ applySortOrder(($0.defensiveTdo ?? 0) < ($1.defensiveTdo ?? 0), sortAscending: defTdoSortAscending) })
        sortField = .DTdo
        defTdoSortAscending = !defTdoSortAscending
    }
    
    private func applySortOrder(condition: Bool, sortAscending: Bool) -> Bool {
        return sortAscending ? condition : !condition
    }

    
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
        
        if let sortField = sortField {
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
            default:
                cell.topLabel.text = "\(pokemon.cp) cp"
            }
        } else {
            cell.topLabel.text = "\(pokemon.cp) cp"
        }
        

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
    
    // MARK: Types

    enum SortField {
        case Recent
        case Name
        case OTdo
        case DTdo
        case Id
        case Cp
        case Iv
    }
}

