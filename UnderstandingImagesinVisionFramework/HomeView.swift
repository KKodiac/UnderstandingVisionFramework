//
//  ContentView.swift
//  UnderstandingImagesinVisionFramework
//
//  Created by Sean Hong on 2022/10/26.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @ObservedObject var dataSource: ImageSource = ImageSource()
    @State private var isImageChosen = false

    var body: some View {
        VStack {
            if self.isImageChosen == false {
                Button("Choose Image") {
                    let panel = NSOpenPanel()
                    panel.message = "Choose images to be classified (folders will be processed recursively)."
                    panel.prompt = "Choose"
                    panel.allowedContentTypes = [.image]
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = true
                    panel.allowsMultipleSelection = true
                    if panel.runModal() == .OK {
                        panel.urls.forEach { url in
                            let image = ImageFile(url: url)
                            dataSource.imageFiles.append(image)
                        }
                        self.isImageChosen.toggle()
                    }
                }
            } else {
                ScrollView {
                    ForEach(dataSource.imageFiles) { image in
                        DetailsView(imageFile: image)
                    }
                }
            }
        }
        .frame(width: 800, height: 600)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
