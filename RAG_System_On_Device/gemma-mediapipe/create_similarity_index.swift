//
//  create_similarity_index.swift
//  gemma-mediapipe
//
//  Created by Omkar Malpure on 28/03/24.
//

import Foundation
import NaturalLanguage



public func vector(for string: String) -> [Double] {
    guard let sentenceEmbedding = NLEmbedding.sentenceEmbedding(for: .english),
          let vector = sentenceEmbedding.vector(for: string) else {
        fatalError()
    }
    return vector
}

public func cosineSimilarity(a: [Double], b: [Double]) -> Double {
    let dotProduct = zip(a, b).map(*).reduce(0, +)
    
    // Calculate the magnitudes
    let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
    let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
    return dotProduct / (magnitudeA * magnitudeB)
}
