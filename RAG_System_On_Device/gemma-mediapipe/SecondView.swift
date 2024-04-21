//
//  SecondView.swift
//  gemma-mediapipe
//
//  Created by Omkar Malpure on 27/03/24.
//

import SwiftUI
import MediaPipeTasksGenAI
struct SecondView: View {
    var data: String
  
    @State private var chunks : [String] = []
    @State private var embeddings : [[Float]] = []
    @State private var messageText = ""
    @State var messages: [String] = ["Welcome to Hushh Bot 2.0!"]
    @State private var IndexArray :[Index] = []
     // Initialize once
//    var init_model = initialise_llm()
    @State private var init_model: LlmInference?
    @State private var json_data:String? = ""
    @State private var similarity_results  = []
    func initialise_llmIfNeeded() {
        if init_model == nil {
            init_model = initialise_llm()
            let user_input = data+"Can you structure this data into json with appropriate format?"
            do{
                json_data = try init_model?.generateResponse(inputText: user_input)
            }
            catch{
                print(error.localizedDescription)
            }
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text("HushhBot")
                    .font(.largeTitle)
                    .bold()

                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 26))
                    .foregroundColor(Color.blue)
                
            }

            ScrollView {
                ForEach(messages, id: \.self) { message in
                    // If the message contains [USER], that means it's us
                    if message.contains("[USER]") {
                        let newMessage = message.replacingOccurrences(of: "[USER]", with: "")

                        // User message styles
                        HStack {
                            Spacer()
                            Text(newMessage)
                                .padding()
                                .foregroundColor(Color.white)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(10)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 10)
                        }
                    } else {

                        // Bot message styles
                        HStack {
                            Text(message)
                                .padding()
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(10)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 10)
                            Spacer()
                        }
                    }

                }.rotationEffect(.degrees(180))
            }
            .rotationEffect(.degrees(180))
            .background(Color.gray.opacity(0.1))


            // Contains the Message bar
            HStack {
                TextField("Type something", text: $messageText)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .onSubmit {

                        sendMessage(message: messageText)

                    }

                Button {
                    sendMessage(message: messageText)

                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .font(.system(size: 26))
                .padding(.horizontal, 10)
            }
            .padding()
            .onAppear{
                initialise_llmIfNeeded()
//                vectorizeChunks(data)
//                On_appear(data)
            }
        }
    }
   
    func On_appear(_ data : String){
//        do{
//            var user_input = data + "You will be acting as a Hushh Bot.You will be provided with some Receipt or Invoice data and you have to answer questions based on that.Don't Give a response for this prompt.Also please be aware of previous questions and responses."
//            let response = try init_model.generateResponse(inputText: user_input)
//        }
//        catch{
//            print("\(error.localizedDescription)")
//        }
        //Generate embeddings
//    let init_embedding_model = DistilbertEmbeddings()
//        let sent_embedding =  init_embedding_model.encode(sentence: data)
//        
//        print(sent_embedding!)
//        print(sent_embedding?.count ?? "No embeddings generated")

    }
    
    func sendMessage(message: String) {
      
        withAnimation {
            messages.append("[USER]" + message)
            self.messageText = ""
            search_index(message)
            print("Similarity Search results")
            print(similarity_results)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {

                    messages.append(botResponse(prompt: message) ?? "Nothing")
                }
            }
        }
    }
    func botResponse(prompt:String)->String?{
        var response :String? = ""
        var user_input = (json_data ?? data)+prompt
        do{
            response = try init_model?.generateResponse(inputText: user_input)
        }
        catch{
            print("Error while generating response!!")
        }
        return response
    }

    
    //Splitting the text , creating embeddings and storing it in an Index
    
    func vectorizeChunks(_ str : String) {
            Task {
                let splitter = RecursiveTokenSplitter(withTokenizer: BertTokenizer())
                let (splitText, _) = splitter.split(text: data,chunkSize: 25 , overlapSize: 7)
                
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
    
    
    
//    func generateResponse(prompt: String) async throws -> String {
//      var partialResult = ""
//      return try await withCheckedThrowingContinuation { continuation in
//        do {
//          try init_model.generateResponseAsync(inputText: prompt) { partialResponse, error in
//            if let error = error {
//              continuation.resume(throwing: error)
//              return
//            }
//            if let partial = partialResponse {
//              partialResult += partial
//            }
//          } completion: {
//            let aggregate = partialResult.trimmingCharacters(in: .whitespacesAndNewlines)
//            continuation.resume(returning: aggregate)
//            partialResult = ""
//          }
//        } catch let error {
//          continuation.resume(throwing: error)
//        }
//      }
//    }
}


#Preview {
    SecondView(data: "")
}
