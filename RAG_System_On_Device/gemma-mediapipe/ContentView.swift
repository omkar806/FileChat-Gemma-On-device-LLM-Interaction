//
//  ContentView.swift
//  gemma-mediapipe
//
//  Created by Omkar Malpure on 25/03/24.
//


import SwiftUI
import PDFKit


struct ContentView:View{
   
    @State private var openFile = false
    @State private var fileName = ""
    @State private var navigatetoSecondView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var fileData = ""

    var body:some View{
        
        NavigationView{
          
            
        VStack{
            
//            Button{
//               
//            }label: {
//                NavigationLink(destination: ThirdView()) {
//                                 Text("RAG System")
//                }
//            }
            
            Button{
                openFile.toggle()
            }label: {
                Text("Upload File")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            VStack{
                NavigationLink(destination: SecondView(data:fileData), isActive: $navigatetoSecondView) { EmptyView() }
            }
        }.fileImporter(isPresented: $openFile, allowedContentTypes: [.pdf,.png,.jpeg,.plainText]){ (res) in
            
            do{
                let fileUrl = try res.get()
                print(fileUrl)
                
                fileData = extractFiledata(fileUrl:fileUrl)
                if !fileData.isEmpty {
                    navigatetoSecondView = true
                    print(navigatetoSecondView)
                    showAlert = true
                    

                    alertMessage = "Text extracted successfully from the file."
                } else {
                    showAlert = true
                    navigatetoSecondView = true

                    alertMessage = "Failed to extract text from the file. Please upload the file again."
                }
            }
            catch{
                print("Error:  \(error.localizedDescription)")
                showAlert = true
                alertMessage = "Error: \(error.localizedDescription). Please upload the file again."
            }
            
           
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
}

#Preview {
    ContentView()
}
