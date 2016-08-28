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
        return [
            Pokemon(nickname: nil, species: "Bulbasaur", pokemonId: 1, isFavorite: false, height: 0.5, weight: 1.5, cp: 100, hp: 30, maxHp: 30, move1: .VineWhipFast, move2: .SludgeBomb, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "char", species: "Charmander", pokemonId: 4, isFavorite: false, height: 1.5, weight: 0.75, cp: 200, hp: 40, maxHp: 40, move1: .EmberFast, move2: .FireBlast, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "Pidg", species: "Pidgey", pokemonId: 16, isFavorite: false, height: 5.2, weight: 8.2, cp: 10, hp: 15, maxHp: 15, move1: .WingAttackFast, move2: .AerialAce, individualAttack: 4, individualDefense: 8, individualStamina: 2, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: nil, species: "Bulbasaur", pokemonId: 1, isFavorite: false, height: 0.5, weight: 1.5, cp: 100, hp: 30, maxHp: 30, move1: .VineWhipFast, move2: .SludgeBomb, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "char", species: "Charmander", pokemonId: 4, isFavorite: false, height: 1.5, weight: 0.75, cp: 200, hp: 40, maxHp: 40, move1: .EmberFast, move2: .FireBlast, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "Pidg", species: "Pidgey", pokemonId: 16, isFavorite: false, height: 5.2, weight: 8.2, cp: 10, hp: 15, maxHp: 15, move1: .WingAttackFast, move2: .AerialAce, individualAttack: 4, individualDefense: 8, individualStamina: 2, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: nil, species: "Bulbasaur", pokemonId: 1, isFavorite: false, height: 0.5, weight: 1.5, cp: 100, hp: 30, maxHp: 30, move1: .VineWhipFast, move2: .SludgeBomb, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "char", species: "Charmander", pokemonId: 4, isFavorite: false, height: 1.5, weight: 0.75, cp: 200, hp: 40, maxHp: 40, move1: .EmberFast, move2: .FireBlast, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "Pidg", species: "Pidgey", pokemonId: 16, isFavorite: false, height: 5.2, weight: 8.2, cp: 10, hp: 15, maxHp: 15, move1: .WingAttackFast, move2: .AerialAce, individualAttack: 4, individualDefense: 8, individualStamina: 2, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: nil, species: "Bulbasaur", pokemonId: 1, isFavorite: false, height: 0.5, weight: 1.5, cp: 100, hp: 30, maxHp: 30, move1: .VineWhipFast, move2: .SludgeBomb, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "char", species: "Charmander", pokemonId: 4, isFavorite: false, height: 1.5, weight: 0.75, cp: 200, hp: 40, maxHp: 40, move1: .EmberFast, move2: .FireBlast, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "Pidg", species: "Pidgey", pokemonId: 16, isFavorite: false, height: 5.2, weight: 8.2, cp: 10, hp: 15, maxHp: 15, move1: .WingAttackFast, move2: .AerialAce, individualAttack: 4, individualDefense: 8, individualStamina: 2, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: nil, species: "Bulbasaur", pokemonId: 1, isFavorite: false, height: 0.5, weight: 1.5, cp: 100, hp: 30, maxHp: 30, move1: .VineWhipFast, move2: .SludgeBomb, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "char", species: "Charmander", pokemonId: 4, isFavorite: false, height: 1.5, weight: 0.75, cp: 200, hp: 40, maxHp: 40, move1: .EmberFast, move2: .FireBlast, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "Pidg", species: "Pidgey", pokemonId: 16, isFavorite: false, height: 5.2, weight: 8.2, cp: 10, hp: 15, maxHp: 15, move1: .WingAttackFast, move2: .AerialAce, individualAttack: 4, individualDefense: 8, individualStamina: 2, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: nil, species: "Bulbasaur", pokemonId: 1, isFavorite: false, height: 0.5, weight: 1.5, cp: 100, hp: 30, maxHp: 30, move1: .VineWhipFast, move2: .SludgeBomb, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "char", species: "Charmander", pokemonId: 4, isFavorite: false, height: 1.5, weight: 0.75, cp: 200, hp: 40, maxHp: 40, move1: .EmberFast, move2: .FireBlast, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "Pidg", species: "Pidgey", pokemonId: 16, isFavorite: false, height: 5.2, weight: 8.2, cp: 10, hp: 15, maxHp: 15, move1: .WingAttackFast, move2: .AerialAce, individualAttack: 4, individualDefense: 8, individualStamina: 2, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: nil, species: "Bulbasaur", pokemonId: 1, isFavorite: false, height: 0.5, weight: 1.5, cp: 100, hp: 30, maxHp: 30, move1: .VineWhipFast, move2: .SludgeBomb, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "char", species: "Charmander", pokemonId: 4, isFavorite: false, height: 1.5, weight: 0.75, cp: 200, hp: 40, maxHp: 40, move1: .EmberFast, move2: .FireBlast, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "Pidg", species: "Pidgey", pokemonId: 16, isFavorite: false, height: 5.2, weight: 8.2, cp: 10, hp: 15, maxHp: 15, move1: .WingAttackFast, move2: .AerialAce, individualAttack: 4, individualDefense: 8, individualStamina: 2, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: nil, species: "Bulbasaur", pokemonId: 1, isFavorite: false, height: 0.5, weight: 1.5, cp: 100, hp: 30, maxHp: 30, move1: .VineWhipFast, move2: .SludgeBomb, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "char", species: "Charmander", pokemonId: 4, isFavorite: false, height: 1.5, weight: 0.75, cp: 200, hp: 40, maxHp: 40, move1: .EmberFast, move2: .FireBlast, individualAttack: 10, individualDefense: 10, individualStamina: 10, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate()),
            Pokemon(nickname: "Pidg", species: "Pidgey", pokemonId: 16, isFavorite: false, height: 5.2, weight: 8.2, cp: 10, hp: 15, maxHp: 15, move1: .WingAttackFast, move2: .AerialAce, individualAttack: 4, individualDefense: 8, individualStamina: 2, battlesAttacked: 0, battlesDefended: 0, timeCaught: NSDate())
        ]
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
        cell.nameLabel.text = pokemon.displayName
        cell.nameLabel.textColor = UIColor.whiteColor()
        cell.ivLabel.text = String(format: "%%%.2f", pokemon.iVPct * 100)
        cell.ivLabel.textColor = UIColor.whiteColor()
        cell.backgroundColor = UIColor.blueColor()
        return cell
    }
}
