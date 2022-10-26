//
//  DetailsViewModel.swift
//  UnderstandingImagesinVisionFramework
//
//  Created by Sean Hong on 2022/10/26.
//

import Foundation
import Vision

class DetailsViewModel: ObservableObject {
    @Published var tableRows: [TableRow] = []

    func convert(_ categories: [String: VNConfidence]) {
        if !categories.isEmpty {            
            tableRows.append(contentsOf: categories.map({ (name, confidence) -> TableRow in
                return TableRow(name: name.formattedCategoryName, confidence: Float(confidence))
            }).sorted(by: { (row1, row2) -> Bool in
                return row1.confidence > row2.confidence
            }))
        }
    }
}
