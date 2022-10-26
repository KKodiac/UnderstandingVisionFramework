//
//  DetailsView.swift
//  UnderstandingImagesinVisionFramework
//
//  Created by Sean Hong on 2022/10/26.
//

import SwiftUI

struct DetailsView: View {
    var imageFile: ImageFile?
    @ObservedObject var image = DetailsViewModel()
    
    var body: some View {
        HStack {
            ScrollView {
                ForEach(image.tableRows, id: \.self) { item in
                    Text("\(item.name) : \(item.confidence)")
                }
            }
            VStack {
                Image(nsImage: imageFile?.thumbnail ?? NSImage())
                Divider()
                Text(imageFile?.name ?? "Error")
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            image.convert(imageFile?.categories ?? [:])
            image.tableRows.forEach{ item in print(item) }
        }
        
    }
}

struct DetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsView()
    }
}
