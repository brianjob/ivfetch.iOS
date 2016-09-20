//
//  SecondarySortController.swift
//  IVFetch
//
//  Created by Brian Barton on 9/16/16.
//  Copyright © 2016 Brian Barton. All rights reserved.
//

import UIKit

class SecondarySortController: UIViewController {

    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var button4: UIButton!
    @IBOutlet weak var button5: UIButton!
    
    var searchablePokemonCollectionViewController: SearchablePokemonCollectionViewController? = nil
    var actions: [UIButton: (() -> Void)] = [:]
    
    var primarySortField: SortField? = nil
    
    override func viewWillAppear(animated: Bool) {
        let buttons = [button1, button2, button3, button4, button5]
        
        var index = 0
        for sortField in SortField.allValues {
            if primarySortField! != sortField {
                buttons[index].setTitle(sortField.rawValue, forState: .Normal)
                buttons[index].addTarget(self, action: #selector(setSecondarySortField), forControlEvents: .TouchUpInside)
                actions[buttons[index]] = {
                    self.searchablePokemonCollectionViewController?.secondarySortField = sortField
                    self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
                }
                index += 1
            }
        }

    }
    
    var secondarySortField: SortField? = nil {
        didSet {
            searchablePokemonCollectionViewController?.secondarySortField = secondarySortField
        }
    }
    
    @objc
    private func setSecondarySortField(sender: UIButton?) {
        if let sender = sender {
            actions[sender]?()
        }
    }
}
