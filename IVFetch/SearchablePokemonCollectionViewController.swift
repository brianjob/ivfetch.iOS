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
    
    @IBOutlet var searchBarContainer: UIView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var searchController: UISearchController?
    
    var sortAscending = true
    
    //MARK: Setup & Teardown
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        print("collection view did load")
        
        collectionView?.backgroundColor = UIColor.darkGrayColor()
        
        //load the data
        //pokemons = loadSampleData()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
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
                                                    bottom: COLLECTION_VIEW_PADDING,
                                                    right: COLLECTION_VIEW_PADDING)
    }
    
    //MARK: Private
    
    private func loadSampleData() -> [Pokemon] {
        var sampleData: [Pokemon] = []
        for _ in 0..<10  {
            sampleData += [
                Pokemon(nickname: nil, species: "Bulbasaur", pokemonId: 1, isFavorite: false, height: 0.5, weight: 1.5, cp: 100, hp: 30, maxHp: 30, move1: .VineWhipFast, move2: .SludgeBomb, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
                Pokemon(nickname: "char", species: "Charmander", pokemonId: 4, isFavorite: false, height: 1.5, weight: 0.75, cp: 200, hp: 40, maxHp: 40, move1: .EmberFast, move2: .FireBlast, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
                Pokemon(nickname: "Pidgey is the greatest pokemon on the entire planet", species: "Pidgey", pokemonId: 16, isFavorite: false, height: 5.2, weight: 8.2, cp: 10, hp: 15, maxHp: 15, move1: .WingAttackFast, move2: .AerialAce, individualAttack: 4, individualDefense: 8, individualStamina: 2, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate())
            ]
        }
        return sampleData
    }
    
    
    private func searchString(string: String, searchTerm:String) -> Bool {
        var matches:Array<AnyObject> = []
        do {
            let regex = try NSRegularExpression(pattern: searchTerm, options: [.CaseInsensitive, .AllowCommentsAndWhitespace])
            let range = NSMakeRange(0, string.characters.count)
            matches = regex.matchesInString(string, options: [], range: range)
        } catch _ {
        }
        return matches.count > 0
    }
    
    private func searchPokemon(pokemon: Pokemon, searchTerm: String) -> Bool {
        return searchString(pokemon.nickname ?? "", searchTerm: searchTerm) ||
               searchString(pokemon.species, searchTerm: searchTerm) ||
               searchString(pokemon.move1Pretty, searchTerm: searchTerm) ||
               searchString(pokemon.move2Pretty, searchTerm: searchTerm )
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
    
    private func setupToolbar() {
        let fixedSpace = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        fixedSpace.width = 5
        
        toolbar?.items = [
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace , target: nil, action: nil),
            UIBarButtonItem(title: "🕐", style: .Plain, target: self, action: #selector(sortRecent)),
            fixedSpace,
            UIBarButtonItem(title: "Name", style: .Plain, target: self, action: #selector(sortName)),
            fixedSpace,
            UIBarButtonItem(title: "#", style: .Plain, target: self, action: #selector(sortSpecies)),
            fixedSpace,
            UIBarButtonItem(title: "CP", style: .Plain, target: self, action: #selector(sortCp)),
            fixedSpace,
            UIBarButtonItem(title: "IV", style: .Plain, target: self, action: #selector(sortIv)),
            fixedSpace
        ]
    }

    @objc private func sortRecent() {
        filteredPokemons.sortInPlace({ applySortOrder($0.timeCaught < $1.timeCaught) })
        toggleSortOrder()
    }
    @objc private func sortName() {
        filteredPokemons.sortInPlace({ applySortOrder($0.displayName.lowercaseString < $1.displayName.lowercaseString) })
        toggleSortOrder()
    }
    @objc private func sortSpecies() {
        filteredPokemons.sortInPlace({ applySortOrder($0.pokemonId < $1.pokemonId) })
        toggleSortOrder()
    }
    @objc private func sortCp() {
        filteredPokemons.sortInPlace({ applySortOrder($0.cp < $1.cp )})
        toggleSortOrder()
    }
    @objc private func sortIv() {
        filteredPokemons.sortInPlace({ applySortOrder($0.ivPct < $1.ivPct) })
        toggleSortOrder()
    }
    
    private func toggleSortOrder() {
        sortAscending = !sortAscending
    }
    private func applySortOrder(condition: Bool) -> Bool {
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
        PokemonCollectionViewCell

        let pokemon = filteredPokemons[indexPath.row]
        
        cell.nameLabel.numberOfLines = 1
        cell.nameLabel.minimumScaleFactor = 0.4
        cell.nameLabel.adjustsFontSizeToFitWidth = true
        cell.nameLabel.text = pokemon.displayName
        
        cell.ivLabel.numberOfLines = 1
        cell.ivLabel.minimumScaleFactor = 0.4
        cell.ivLabel.adjustsFontSizeToFitWidth = true
        cell.ivLabel.text = String(format: "%%%.2f", pokemon.ivPct)
        
        cell.cpLabel.numberOfLines = 1
        cell.ivLabel.minimumScaleFactor = 0.4
        cell.cpLabel.adjustsFontSizeToFitWidth = true
        cell.cpLabel.text = "\(pokemon.cp) CP"
        
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
            }
        } else if let loginController = segue.destinationViewController as? LoginViewController {
            loginController.logout()
        }
        
        // hide the keyboard
        if ((searchController?.searchBar.isFirstResponder()) != nil) {
            searchController?.searchBar.resignFirstResponder()
            searchController?.active = false
        }
    }

}

