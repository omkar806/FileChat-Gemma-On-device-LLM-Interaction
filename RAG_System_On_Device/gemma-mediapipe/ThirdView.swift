//
//  ThirdView.swift
//  gemma-mediapipe
//
//  Created by Omkar Malpure on 02/04/24.
//

import SwiftUI
import PDFKit
import MetalPerformanceShadersGraph

struct ThirdView: View {
    @State private var openFile = false
    @State private var fileName = ""
    @State private var navigatetoSecondView = false
    @State private var showAlert = false
    @State private var fileData = ""
    @State private var IndexArray :[Index] = []
    @State private var similarity_results : [String] = []
    @State private var chunks : [String] = []
    @State private var embeddings : [[Float]] = []
    @State private var showEmbeddingindexbutton = false
    @State private var showIndexElements = false
    @State private var user_prompt = ""
    @State private var showTextField = false
    @State private var showsimilarityresults = false
    
    
    var body: some View {
        VStack{
        Button{
            openFile.toggle()
        }label: {
            Text("Upload File")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
            
            if showTextField {
                HStack {
                    TextField("Enter your Query ?", text: $user_prompt) {
                        // Perform actions when the user presses Enter
                        search_index(user_prompt)
                    }
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        // Perform actions when the user taps the search icon
                        search_index(user_prompt)
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Display search results
            if showsimilarityresults {
                List(similarity_results.prefix(1), id: \.self) { result in
                    Text(result)
                }
            }
            

    if showEmbeddingindexbutton {
        Button{
            vectorizeChunks()
            showIndexElements = true
            showTextField = true

        }label: {
            Text("Embed And Index")
        }
    }
    
//    if showIndexElements {
//        VStack {
//            ForEach(0..<IndexArray.count) { index in
//                let embeddingsArray = NSArray(array: IndexArray[index].embeddings[0...3].map { NSNumber(value: $0) })
//
//                Text("Chunk : \(chunks[IndexArray[index].id]), Embeddings : \(embeddingsArray)")
//            }
//            
//            Button{
//                showTextField = true
//            }label: {
//                Text("Search through documents.")
//            }
//        }
//    }
    
        
    
        
        
    }.fileImporter(isPresented: $openFile, allowedContentTypes: [.pdf,.png,.jpeg,.plainText]){ (res) in
        
        do{
            let fileUrl = try res.get()
            print(fileUrl)
            
            fileData = extractFiledata(fileUrl:fileUrl)
            if !fileData.isEmpty {
                navigatetoSecondView = true
                print(navigatetoSecondView)
                showAlert = true
                showEmbeddingindexbutton = true

            
            } else {
                showAlert = true
                navigatetoSecondView = true
            }
        }
        catch{
            print("Error:  \(error.localizedDescription)")
            
        }
        
       
    }

        
        
        
    }
    
    
    func extractExxtension(fileUrl : URL)->String{
        fileUrl.pathExtension
    }
    func extractFiledata(fileUrl:URL)->String{
        var text = ""
        if fileUrl.pathExtension == "pdf" {
            text = extractTextPDF(pdfURL: fileUrl) ?? "Failed in extracting Text from the PDF \(fileUrl.lastPathComponent)"
            print("Printing text for PDFs")
            print(text)
        }
        else if fileUrl.pathExtension == "txt"{
            text = extractTextTxt(txtURL: fileUrl) ?? "Failed in extracting Text from the PDF \(fileUrl.lastPathComponent)"
        }
        else if fileUrl.pathExtension == "jgp" || fileUrl.pathExtension == "jpeg"{
            text = extractTextImage(imgPath:fileUrl) ?? "Failed in extracting Text from the PDF \(fileUrl.lastPathComponent)"
        }
        else{
            print("Error while extracting the text from the File")
        }
        return text
    }
    
    func extractTextPDF(pdfURL:URL)->String?{
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
                print("Failed to create PDF document.")
                return nil
            }
            
            var extractedText = ""
            
            for i in 0..<pdfDocument.pageCount {
                guard let page = pdfDocument.page(at: i) else {
                    print("Failed to get page \(i + 1) from PDF document.")
                    continue
                }
                
                guard let pageText = page.string else {
                    print("Failed to extract text from page \(i + 1) of the PDF document.")
                    continue
                }
                
                extractedText += pageText
            }
            
            return extractedText
        }
    
    
    func extractTextImage(imgPath:URL)->String?{
        print("Don't Choose Image Files.")
        return ""
    }
    
    func extractTextTxt(txtURL:URL)->String?{
        do {
            let text = try String(contentsOf: txtURL, encoding: .utf8)
            return text
        } catch {
            print("Error reading text file: \(error)")
            return nil
        }
    }
    
    
    func vectorizeChunks() {
            Task {
                let splitter = RecursiveTokenSplitter(withTokenizer: BertTokenizer())
                let (splitText, _) = splitter.split(text: fileData,chunkSize: 25 , overlapSize: 7)
                
                chunks = splitText
                print("Printing Chunks")
                print(chunks)
                embeddings = []
                let embeddingModel = DistilbertEmbeddings()
                
                for chunk in chunks {
                    if let embedding = embeddingModel.encode(sentence: chunk) {
                        embeddings.append(embedding)
                    }
                }
//                print("Printing Embeddings Array")
//                print(embeddings)
                
                print("Creating an Index")
                for (idx, chunk) in chunks.enumerated() {
                    let vector = embeddings[idx]
                    IndexArray.append(Index(id: idx, embeddings: vector))
                    
                }
                print("Printing the Index")
                for idx in IndexArray.indices{
                  let indexx = IndexArray[idx]
                    print(indexx.id)
                    print(indexx.embeddings[0...10])
                }
            }
        
        
        

        
        }
    
    
    func search_index(_ qry:String){
        
        var similarities : [Int:Float] = [:]
        
        for idx in IndexArray.indices {
            let indexx = IndexArray[idx]
            let similarity_score = cosineSimilarity(DistilbertEmbeddings().encode(sentence: qry)!,indexx.embeddings ) // Assuming qryEmbeddings is the embeddings for the query
            similarities[idx] = similarity_score
        }
    
        let sortedSimilarities = similarities.sorted { $0.value < $1.value }
        for idxx in sortedSimilarities.indices {
            similarity_results.append(chunks[idxx])
        }
        showsimilarityresults = true
    }
    
    // Define a function to calculate similarity between two embeddings
    func cosineSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float {
        // Calculate dot product
        let dotProduct = zip(embedding1, embedding2).map { $0 * $1 }.reduce(0, +)
        
        // Calculate magnitudes
        let magnitude1 = sqrt(embedding1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(embedding2.map { $0 * $0 }.reduce(0, +))
        
        // Calculate cosine similarity
        guard magnitude1 != 0 && magnitude2 != 0 else { return 0 } // Avoid division by zero
        return dotProduct / (magnitude1 * magnitude2)
    }
    
    
}

#Preview {
    ThirdView()
}
