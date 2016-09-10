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
    let REUSE_IDENTIFIER = "PokemonCell"
    let COLLECTION_VIEW_PADDING = CGFloat(10)
    let TOOLBAR_FONT_NAME = "Helvetica"
    let TOOLBAR_FONT_SIZE = CGFloat(20)
    let TOOLBAR_PADDING = CGFloat(10)
    
    var pokemonService: PokemonService? = nil
    var errorMessage: String? = nil

    var pokemons: [Pokemon] = [Pokemon]() {
        didSet {
            filterData()
        }
    }
    
    var filteredPokemons = [Pokemon]() {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    var currentSearchQuery: String? = nil
    
    // MARK: Outlets
    
    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var searchController: UISearchController?
    
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
    
//    override func viewDidAppear(animated: Bool) {
//        searchController?.searchBar.text = currentSearchQuery
//        filterData()
//    }
    
    //MARK: Private

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
    
    func filterData() {
        if (searchIsEmpty()) {
            filteredPokemons = pokemons
        } else {
            filteredPokemons = pokemons.filter({ (pokemon) -> Bool in
                let searchTerm = self.searchController!.searchBar.text!
                return searchPokemon(pokemon, searchTerm: searchTerm)
            })
        }
    }
    
    private func setupToolbar() {
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        fixedSpace.width = TOOLBAR_PADDING
        
        let recentButton = UIBarButtonItem(image: UIImage(named: "clock-48"),
                                           style: .Plain, target: self, action: #selector(sortRecent))

        toolbar?.items = [
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace , target: nil, action: nil),
            recentButton,
            fixedSpace,
            makeBarButtonItem("Off.", action: #selector(sortOffTdo)),
            fixedSpace,
            makeBarButtonItem("Def.", action: #selector(sortDefTdo)),
            fixedSpace,
            makeBarButtonItem("#", action: #selector(sortSpecies)),
            fixedSpace,
            makeBarButtonItem("CP", action: #selector(sortCp)),
            fixedSpace,
            makeBarButtonItem("IV", action: #selector(sortIv)),
            fixedSpace
        ]
    }
    
    private func makeBarButtonItem(title: String, action: Selector) -> UIBarButtonItem {
        let buttonItem = UIBarButtonItem(title: title, style: .Plain, target: self, action: action)
        buttonItem.setTitleTextAttributes([
            NSFontAttributeName: UIFont(name: TOOLBAR_FONT_NAME, size: TOOLBAR_FONT_SIZE)!],
                                          forState: UIControlState.Normal)

        return buttonItem
    }

    private var recentSortAscending = false
    @objc private func sortRecent() {
        filteredPokemons.sortInPlace({ applySortOrder($0.timeCaught < $1.timeCaught, sortAscending: recentSortAscending) })
        recentSortAscending = !recentSortAscending
    }
    private var nameSortAscending = false
    @objc private func sortName() {
        filteredPokemons.sortInPlace({ applySortOrder($0.displayName.lowercaseString < $1.displayName.lowercaseString, sortAscending: nameSortAscending) })
        nameSortAscending = !nameSortAscending
    }
    private var speciesSortAscending = false
    @objc private func sortSpecies() {
        filteredPokemons.sortInPlace({ applySortOrder($0.pokemonId < $1.pokemonId, sortAscending: speciesSortAscending) })
        speciesSortAscending = !speciesSortAscending
    }
    private var cpSortAscending = false
    @objc private func sortCp() {
        filteredPokemons.sortInPlace({ applySortOrder($0.cp < $1.cp, sortAscending: cpSortAscending)})
        cpSortAscending = !cpSortAscending
    }
    private var ivSortAscending = false
    @objc private func sortIv() {
        filteredPokemons.sortInPlace({ applySortOrder($0.ivPct < $1.ivPct, sortAscending: ivSortAscending) })
        ivSortAscending = !ivSortAscending
    }
    private var offTdoSortAscending = false
    @objc private func sortOffTdo() {
        filteredPokemons.sortInPlace({ applySortOrder(($0.offensiveTdo ?? 0) < ($1.offensiveTdo ?? 0), sortAscending: offTdoSortAscending) })
        offTdoSortAscending = !offTdoSortAscending
    }
    private var defTdoSortAscending = false
    @objc private func sortDefTdo() {
        filteredPokemons.sortInPlace({ applySortOrder(($0.defensiveTdo ?? 0) < ($1.defensiveTdo ?? 0), sortAscending: defTdoSortAscending) })
        defTdoSortAscending = !defTdoSortAscending
    }
    
    private func applySortOrder(condition: Bool, sortAscending: Bool) -> Bool {
        return sortAscending ? condition : !condition
    }
    
    // sets common attributes for labels within collection cell
    private func setupCellLabel(label: UILabel) {
        label.numberOfLines = 1
        label.minimumScaleFactor = 0.4
        label.adjustsFontSizeToFitWidth = true
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
        PokemonCollectionViewCell

        let pokemon = filteredPokemons[indexPath.row]
        
        setupCellLabel(cell.nameLabel)
        setupCellLabel(cell.ivLabel)
        setupCellLabel(cell.cpLabel)
        setupCellLabel(cell.tdoLabel)
        cell.nameLabel.text = pokemon.displayName
        cell.ivLabel.text = String(format: "%.1f%%", pokemon.ivPct)
        cell.cpLabel.text = "\(pokemon.cp) CP"
        cell.tdoLabel.text = ("\(pokemon.offensiveTdo ?? 0)/\(pokemon.defensiveTdo ?? 0) TDO")
        
        cell.layer.cornerRadius = 6
        
        return cell
    }
    
    //MARK: UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView)
    {
        //dismiss the keyboard if the search results are scrolled
        searchController?.searchBar.resignFirstResponder()
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let pokemonDetailViewController = segue.destinationViewController as? PokemonDetailViewController {
            
            if let selectedPokemonCell = sender as? PokemonCollectionViewCell {
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

