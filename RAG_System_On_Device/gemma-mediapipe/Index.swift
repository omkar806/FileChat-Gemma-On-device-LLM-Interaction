//
//  Index.swift
//  gemma-mediapipe
//
//  Created by Omkar Malpure on 29/03/24.
//

import Foundation

struct Index : Identifiable{
    
    let id : Int
    let embeddings:[Float]
    
}

func insert_index(id:Int , embedding:[Float])->Index{
    let newIndex = Index(id: id, embeddings: embedding)
    return newIndex
}
