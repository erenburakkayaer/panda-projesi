import SwiftUI

struct LaunchScreenView: View {
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 20) {
                Image("panda_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                
                Text("İyi Çalışmalar")
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .medium, design: .rounded))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isActive = true
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            ContentView()
        }
    }
}

#Preview {
    LaunchScreenView()
}

