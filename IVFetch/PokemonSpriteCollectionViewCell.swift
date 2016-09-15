//
//  PokemonSpriteCollectionViewCell.swift
//  IVFetch
//
//  Created by Brian Barton on 9/13/16.
//  Copyright © 2016 Brian Barton. All rights reserved.
//

import UIKit

class PokemonSpriteCollectionViewCell: UICollectionViewCell {
    
    private let SPRITE_SHEET_NUM_COLS = 31
    private let SPRITE_SHEET_NUM_ROWS = 24
    private let SHEET_WIDTH = 1736.0
    private let SHEET_HEIGHT = 1344.0
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var bottomLabel: UILabel!
    
    var pokemonId: Int? = nil {
        didSet {
            let spriteSheet = UIImage(named: "pokemon-sprites")
            let spriteWidth = CGFloat(SHEET_WIDTH / Double(SPRITE_SHEET_NUM_COLS))
            let spriteHeight = CGFloat(SHEET_HEIGHT / Double(SPRITE_SHEET_NUM_ROWS))
            let x = xOffset(pokemonId!, width: spriteWidth)
            let y = yOffset(pokemonId!, height: spriteWidth)
            let rect = CGRectMake(x, y, spriteWidth, spriteHeight)
            let image = CGImageCreateWithImageInRect(spriteSheet?.CGImage, rect)
            
            imageView.image = UIImage(CGImage: image!)
            imageView.contentMode = .ScaleAspectFit
        }
    }
    
    private func xOffset(id: Int, width: CGFloat) -> CGFloat {
        return (CGFloat((id - 1) % SPRITE_SHEET_NUM_COLS) * width)
    }
    
    private func yOffset(id: Int, height: CGFloat) -> CGFloat {
        return (CGFloat((id - 1) / SPRITE_SHEET_NUM_COLS) * height)
    }
}
