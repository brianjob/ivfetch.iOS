//
//  SortField.swift
//  IVFetch
//
//  Created by Brian Barton on 9/16/16.
//  Copyright © 2016 Brian Barton. All rights reserved.
//

import Foundation

enum SortField : String {
    case Recent = "Recent", OTdo = "Off", DTdo = "Def", Id = "#", Cp = "CP", Iv = "IV"
    
    static let allValues = [Recent, OTdo, DTdo, Id, Cp, Iv]
}