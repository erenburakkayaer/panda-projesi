import SwiftUI
import AVFoundation
import PDFKit

struct ContentView: View {
    @StateObject private var speechEngine = SpeechEngine()
    @State private var textToSpeak = "PDF seçmek için butona basın veya buraya metin yapıştırın."
    @State private var showDocumentPicker = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    Text("Panda sesli yapay zeka")
                        .font(.title2)
                        .bold()
                }
                .padding(.top)
                
                ZStack {
                    TextEditor(text: $textToSpeak)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    
                    if isLoading {
                        ProgressView("PDF Okunuyor...")
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                    }
                }

                VStack(spacing: 12) {

                    Button(action: { showDocumentPicker = true }) {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text("PDF Dosyası Seç")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    HStack(spacing: 10) {

                        Button(action: {
                            speechEngine.stop()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                speechEngine.speak(text: textToSpeak)
                            }
                        }) {
                            VStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title2)
                                Text("Baştan")
                                    .font(.caption)
                            }
                            .frame(width: 80, height: 60)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        Button(action: {
                            if speechEngine.isSpeaking {
                                if speechEngine.isPaused {
                                    speechEngine.resume()
                                } else {
                                    speechEngine.pause()
                                }
                            } else {
                                speechEngine.speak(text: textToSpeak)
                            }
                        }) {
                            HStack {
                                Image(systemName: speechEngine.isSpeaking && !speechEngine.isPaused ? "pause.fill" : "play.fill")
                                    .font(.title2)
                                Text(speechEngine.isPaused ? "Devam Et" : (speechEngine.isSpeaking ? "Duraklat" : "Oku"))
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(speechEngine.isSpeaking && !speechEngine.isPaused ? Color.orange : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        Button(action: { speechEngine.stop() }) {
                            VStack {
                                Image(systemName: "stop.fill")
                                    .font(.title2)
                                Text("Bitir")
                                    .font(.caption)
                            }
                            .frame(width: 80, height: 60)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    
                    Button("Panodan Metin Yapıştır") {
                        if let clipboard = UIPasteboard.general.string {
                            textToSpeak = clipboard
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(text: $textToSpeak, isLoading: $isLoading)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}


struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var text: String
    @Binding var isLoading: Bool
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        
        init(parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            parent.isLoading = true
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let pdfDocument = PDFDocument(url: url) {
                    var extractedText = ""
                    for i in 0..<pdfDocument.pageCount {
                        if let page = pdfDocument.page(at: i) {
                            extractedText += (page.string ?? "") + "\n"
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.parent.text = extractedText
                        self.parent.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.parent.isLoading = false
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
