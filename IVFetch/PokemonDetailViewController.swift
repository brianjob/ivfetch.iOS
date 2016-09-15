//
//  PokemonDetailViewController.swift
//  IVFetch
//
//  Created by Brian Barton on 8/27/16.
//  Copyright © 2016 Brian Barton. All rights reserved.
//

import UIKit

class PokemonDetailViewController: UITableViewController {
    let CELL_IDENTIFIER = "PokemonDetailViewCell"
    var pokemon: Pokemon? {
        didSet {
           updatePokemonTable()
        }
    }
    private var pokemonTable: PokemonTable?
    
    override func viewDidLoad() {
        tableView.allowsSelection = false
    }
    
    private func updatePokemonTable() {
        let fmt = NSDateFormatter()
        fmt.dateFormat = "M/d/yy h:mm a"
        
        if let pokemon = pokemon {
            pokemonTable = PokemonTable(sections: [
                PokemonTableSection(name: "Bio", order: 1, cells: [
                    PokemonTableCell(label: "Nickname", value: pokemon.nickname ?? ""),
                    PokemonTableCell(label: "Species", value: "\(pokemon.speciesPretty) [\(pokemon.pokemonId)]"),
                    PokemonTableCell(label: "Type", value: pokemon.type),
                    PokemonTableCell(label: "Favorite", value: pokemon.isFavorite ? "Yes" : "No"),
                    PokemonTableCell(label: "Height", value: "\(String(format: "%.2f", pokemon.height)) m"),
                    PokemonTableCell(label: "Weight", value: "\(String(format: "%.2f", pokemon.weight)) kg")
                    ]),

                PokemonTableSection(name: "Stats", order: 2, cells: [
                    PokemonTableCell(label: "CP", value: String(pokemon.cp)),
                    PokemonTableCell(label: "Attack", value: String(pokemon.attack)),
                    PokemonTableCell(label: "Defense", value: String(pokemon.defense)),
                    PokemonTableCell(label: "HP", value: String(pokemon.maxHp)),
                    PokemonTableCell(label: "Effective HP", value: String(pokemon.eHp)),
                    PokemonTableCell(label: "IV", value: "\(pokemon.individualAttack)/\(pokemon.individualDefense)/\(pokemon.individualStamina) [\(String(format: "%.2f", pokemon.ivPct))%]"),
                    ]),
                
                PokemonTableSection(name: "Moves", order: 3, cells: [
                    PokemonTableCell(label: "Quick Move", value: pokemon.fastMoveName),
                    PokemonTableCell(label: "Quick Move Type", value: pokemon.fastMoveType),
                    PokemonTableCell(label: "Special Move", value: pokemon.specialMoveName),
                    PokemonTableCell(label: "Special Move Type", value: pokemon.specialMoveType),
                    PokemonTableCell(label: "Useless Special?", value:
                        {
                            if pokemon.isSpecialMoveUseless == nil  {
                                return "N/A"
                            } else {
                                return pokemon.isSpecialMoveUseless! ? "Yes" : "No"
                            }
                        }()
                    ),
                    PokemonTableCell(label: "Quick Move DPS", value: optionalDouble2String(pokemon.fastDps)),
                    PokemonTableCell(label: "Combo DPS", value: optionalDouble2String(pokemon.comboDps)),
                    PokemonTableCell(label: "Offensive TDO", value: optionalInt2String(pokemon.offensiveTdo)),
                    PokemonTableCell(label: "Off. Efficiency", value: "\(optionalDouble2String(pokemon.offensiveEfficiency))%"),
                    PokemonTableCell(label: "Defensive TDO", value: optionalInt2String(pokemon.defensiveTdo)),
                    PokemonTableCell(label: "Def. Efficiency", value: "\(optionalDouble2String(pokemon.defensiveEfficiency))%"),
                    ]),
                
                PokemonTableSection(name: "History", order: 4, cells: [
                    PokemonTableCell(label: "Gyms Battles", value: String(pokemon.battles)),
                    PokemonTableCell(label: "Date Caught", value: fmt.stringFromDate(pokemon.timeCaught))
                    ])
                ])
        }
    }
    
    private func optionalInt2String(value: Int?) -> String {
        return value == nil ? "" : String(value!)
    }
    
    private func optionalDouble2String(value: Double?) -> String {
        return value == nil ? "" : String(format: "%.01f", value!)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return pokemonTable!.getNumSections()
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return pokemonTable!.getSectionName(atSection: section)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pokemonTable!.getCellCount(atSection: section)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER, forIndexPath: indexPath)
        
        let pokemonCell = pokemonTable!.getCell(atSection: indexPath.section, atCell: indexPath.row)

        cell.textLabel?.text = pokemonCell.label
        cell.detailTextLabel?.text = pokemonCell.value
       
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    
    private struct PokemonTable {
        var sections: [PokemonTableSection] {
            didSet {
                sections.sortInPlace({ $0.order < $1.order})
            }
        }
        
        init(sections: [PokemonTableSection]) {
            self.sections = sections
        }
        
        func getNumSections() -> Int {
            return sections.count
        }
        
        func getCellCount(atSection section: Int) -> Int {
            return sections[section].cells.count
        }
        
        func getSectionName(atSection section: Int) -> String {
            return sections[section].name
        }
        
        func getCell(atSection section: Int, atCell cell: Int) -> PokemonTableCell {
            return sections[section].cells[cell]
        }
    }
    
    private struct PokemonTableSection {
        var name: String
        var order: Int
        var cells: [PokemonTableCell]
        
        init(name: String, order: Int, cells: [PokemonTableCell]) {
            self.name = name
            self.order = order
            self.cells = cells
        }
    }
    
    private struct PokemonTableCell {
        var label: String
        var value: String
        
        init(label: String, value: String) {
            self.label = label
            self.value = value
        }
    }
}
