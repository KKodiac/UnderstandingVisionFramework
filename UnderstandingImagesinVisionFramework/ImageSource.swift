//
//  ImageSource.swift
//  UnderstandingImagesinVisionFramework
//
//  Created by Sean Hong on 2022/10/26.
//

import SwiftUI
import Vision

extension String {
    var formattedCategoryName: String {
        return self.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

struct ImageFile: Identifiable {
    let id = UUID()
    let url: URL
    let thumbnail: NSImage?
    let name: String
    let categories: [String: VNConfidence]
    let searchTerms: [String: VNConfidence]
    
    init(url: URL) {
        // generate thumbnail
        var thumbnail: NSImage?
        let imageSource = CGImageSourceCreateWithURL(url.absoluteURL as CFURL, nil)
        if let imageSource = imageSource, CGImageSourceGetType(imageSource) != nil {
            let options: [String: Any] = [String(kCGImageSourceCreateThumbnailFromImageIfAbsent): true,
                                           String(kCGImageSourceThumbnailMaxPixelSize): 256]
            if let thumbnailRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) {
                thumbnail = NSImage(cgImage: thumbnailRef, size: NSSize.zero)
            }
        }
        self.thumbnail = thumbnail
        self.url = url
        self.name = url.lastPathComponent

        // Classify the images
        let handler = VNImageRequestHandler(url: url, options: [:])
        let request = VNClassifyImageRequest()
        try? handler.perform([request])
        
        // Process classification results
        guard let observations = request.results as? [VNClassificationObservation] else {
            categories = [:]
            searchTerms = [:]
            return
        }
        categories = observations
            .filter { $0.hasMinimumRecall(0.01, forPrecision: 0.9) }
            .reduce(into: [String: VNConfidence]()) { dict, observation in dict[observation.identifier] = observation.confidence }
            
        searchTerms = observations
            .filter { $0.hasMinimumPrecision(0.01, forRecall: 0.7) }
            .reduce(into: [String: VNConfidence]()) { (dict, observation) in dict[observation.identifier] = observation.confidence }
    }
}


class ImageSource: ObservableObject {
    @Published var imageFiles = [ImageFile]()
    private var imageIndexByCategory = [String: IndexSet]()
    private var imageIndexBySearchTerms = [String: IndexSet]()
    private var searchResults: [String: IndexSet]?
    
    
    func loadData(inputURLs: [URL], reportTotal: @escaping (Int) -> Void,
                  reportProgress: @escaping (Int) -> Void,
                  completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileURLs = self.getImageFileURLs(from: inputURLs)
            reportTotal(fileURLs.count)
            self.imageFiles.removeAll()
            for imageIndex in fileURLs.indices {
                reportProgress(imageIndex + 1)
                let fileURL = fileURLs[imageIndex]
                let imageFile = ImageFile(url: fileURL)
                self.imageFiles.append(imageFile)
                var categories = Array(imageFile.categories.keys)
                if categories.isEmpty {
                    categories = ["other"]
                }
                for category in categories {
                    if self.imageIndexByCategory.index(forKey: category) != nil {
                        self.imageIndexByCategory[category]?.insert(imageIndex)
                    } else {
                        self.imageIndexByCategory[category] = [imageIndex]
                    }
                }
                let searchTerms = Array(imageFile.searchTerms.keys)
                for searchTerm in searchTerms {
                    if self.imageIndexBySearchTerms.keys.contains(searchTerm) {
                        self.imageIndexBySearchTerms[searchTerm]?.insert(imageIndex)
                    } else {
                        self.imageIndexBySearchTerms[searchTerm] = [imageIndex]
                    }
                }
            }
            completion()
        }
    }
    
    func performSearch(_ string: String, completion: () -> Void) {
        let searchTerm = string.lowercased()
        if string.isEmpty {
            searchResults = nil
        } else {
            searchResults = imageIndexBySearchTerms.filter({ (key, _) -> Bool in
                return key.contains(searchTerm)
            })
        }
        completion()
    }
    
    private var sections: [String: IndexSet] {
        if let results = searchResults {
            return results
        } else {
            return imageIndexByCategory
        }
    }

    private var sortedSectionNames: [String] {
        return sections.keys.sorted(by: { key1, key2 in
            if key1 == "other" {
                return false
            } else if key2 == "other" {
                return true
            } else {
                return key1 < key2
            }
        })
    }
    
    private func imageIndices(inSection index: Int) -> IndexSet {
        let name = sortedSectionNames[index]
        guard let indices = sections[name] else {
            fatalError("Unrecognized section name: \(name)")
        }
        return indices
    }
    
    var numberOfSections: Int {
        return sections.count
    }
    
    func sectionName(at index: Int) -> String {
        return sortedSectionNames[index]
    }
    
    func numberOfImages(inSection index: Int) -> Int {
        return imageIndices(inSection: index).count
    }
    
    func imageFile(at index: Int, inSection sectionIndex: Int) -> ImageFile {
        let indices = imageIndices(inSection: sectionIndex)
        let imageIndex = indices[indices.index(indices.startIndex, offsetBy: index)]
        return imageFiles[imageIndex]
    }
    
    let keys: Set<URLResourceKey> = [.isDirectoryKey, .typeIdentifierKey]
    
    private func getImageFileURLs(from inputURLs: [URL]) -> [URL] {
        var filesList = [URL]()
        for url in inputURLs {
            guard let resValues = try? url.resourceValues(forKeys: keys) else {
                continue
            }
            if let isDir = resValues.isDirectory, isDir == true {
                filesList.append(contentsOf: getImageFileURLs(from: getFileURLsFromFolder(url)))
            } else if let uti = resValues.typeIdentifier, UTTypeConformsTo(uti as CFString, "public.image" as CFString) {
                filesList.append(url)
            }
        }
        return filesList
    }
    
    private func getFileURLsFromFolder(_ url: URL) -> [URL] {
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
        let fileMgr = FileManager.default

        guard let content = try? fileMgr.contentsOfDirectory(at: url, includingPropertiesForKeys: Array(keys), options: options) else {
            return []
        }

        return content
    }
}

