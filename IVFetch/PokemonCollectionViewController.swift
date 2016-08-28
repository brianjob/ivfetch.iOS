//
//  PokemonCollectionViewController.swift
//  IVFetch
//
//  Created by Brian Barton on 8/27/16.
//  Copyright © 2016 Brian Barton. All rights reserved.
//

import UIKit

class PokemonCollectionViewController : UICollectionViewController {
    let REUSE_IDENTIFIER = "PokemonCell"
    
    var pokemonService: PokemonService? = nil
    var errorMessage: String? = nil
    var pokemons: [Pokemon]? {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        print("view loaded")
        collectionView?.backgroundColor = UIColor.whiteColor()
        //pokemons = loadSampleData()
    }
    
    func loadSampleData() -> [Pokemon] {
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
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (pokemons?.count) ?? 0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(REUSE_IDENTIFIER, forIndexPath: indexPath) as!
            PokemonCollectionViewCell
        let pokemon = pokemons![indexPath.row]
        
        cell.nameLabel.numberOfLines = 1
        cell.nameLabel.minimumScaleFactor = 0.4
        cell.nameLabel.adjustsFontSizeToFitWidth = true
        cell.nameLabel.text = pokemon.displayName
        cell.nameLabel.textColor = UIColor.blueColor()
        
        cell.ivLabel.numberOfLines = 1
        cell.ivLabel.minimumScaleFactor = 0.4
        cell.ivLabel.adjustsFontSizeToFitWidth = true
        cell.ivLabel.text = String(format: "%%%.2f", pokemon.ivPct)
        cell.ivLabel.textColor = UIColor.blueColor()
        
        cell.cpLabel.numberOfLines = 1
        cell.ivLabel.minimumScaleFactor = 0.4
        cell.cpLabel.adjustsFontSizeToFitWidth = true
        cell.cpLabel.text = "\(pokemon.cp) CP"
        cell.cpLabel.textColor = UIColor.blueColor()
        
        cell.backgroundColor = UIColor.grayColor()
        return cell
    }
    
    // MARK: Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let pokemonDetailViewController = segue.destinationViewController as? PokemonDetailViewController {
            
            if let selectedPokemonCell = sender as? PokemonCollectionViewCell {
                let indexPath = collectionView!.indexPathForCell(selectedPokemonCell)!
                let selectedPokemon = pokemons![indexPath.row]
                pokemonDetailViewController.pokemon = selectedPokemon
            }
        }
    }
}
