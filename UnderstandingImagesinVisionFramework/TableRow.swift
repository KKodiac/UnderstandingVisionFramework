//
//  TableRow.swift
//  UnderstandingImagesinVisionFramework
//
//  Created by Sean Hong on 2022/10/26.
//

import Foundation

struct TableRow: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var confidence: Float
}
