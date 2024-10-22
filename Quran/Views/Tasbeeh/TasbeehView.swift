//
//  TasbeehView.swift
//  Quran
//
//  Created by Ali Earp on 31/08/2024.
//

import SwiftUI

struct TasbeehView: View {
    @State private var count: Int = 0
    
    var body: some View {
        ZStack {
            Button {
                incrementCounter()
            } label: {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack(spacing: 50) {
                Spacer()
                
                incrementButton
                dhikrText
                
                Spacer()
                
                HStack {
                    reduceButton
                    
                    Spacer()
                    
                    resetButton
                }
            }.padding()
        }
        .onAppear {
            DispatchQueue.main.async {
                AppDelegate.orientationLock = UIInterfaceOrientationMask.portrait
                
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            }
        }.onDisappear {
            DispatchQueue.main.async {
                AppDelegate.orientationLock = UIInterfaceOrientationMask.allButUpsideDown
            }
        }
        .navigationTitle("Tasbeeh")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var incrementButton: some View {
        Button {
            incrementCounter()
        } label: {
            incrementButtonLabel
        }
    }
    
    private var incrementButtonLabel: some View {
        VStack(spacing: 15) {
            mainCount
            
            totalCount
        }
        .frame(width: 150, height: 150)
        .background(Color(.secondarySystemBackground))
        .clipShape(Circle())
    }
    
    private var mainCount: some View {
        Group {
            if count < 34 {
                Text(String(count))
            } else if count < 67 {
                Text(String(count - 34))
            } else {
                Text(String(count - 67))
            }
        }
        .font(.system(size: 45, weight: .bold, design: .rounded))
        .foregroundStyle(Color.primary)
    }
    
    private var totalCount: some View {
        Text(String(count))
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(Color.secondary)
    }
    
    private func incrementCounter() {
        withAnimation(nil) {
            if count < 100 {
                count += 1
                
                if count == 34 || count == 67 || count == 100 {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } else {
                count = 0
            }
        }
    }
    
    private var dhikrText: some View {
        VStack(spacing: 15) {
            let fontNumber = UserDefaultsController.shared.integer(forKey: "fontNumber")
            
            let defaultFont = Font.system(size: CGFloat(UserDefaultsController.shared.double(forKey: "fontSize")), weight: .bold)
            let uthmanicFont = Font.custom("KFGQPCUthmanicScriptHAFS", size: CGFloat(UserDefaultsController.shared.double(forKey: "fontSize")))
            let notoNastaliqFont = Font.custom("NotoNastaliqUrdu", size: CGFloat(UserDefaultsController.shared.double(forKey: "fontSize")))
            
            let font = fontNumber == 1 ? defaultFont : fontNumber == 2 ? uthmanicFont : notoNastaliqFont
            
            if count < 34 {
                Text("ٱللَّٰهُ أَكْبَرُ")
                    .font(font)
                
                Text("ALLAHUAKBAR")
                    .foregroundStyle(Color.secondary)
                
                Text("Allah is Greatest")
            } else if count < 67 {
                Text("ٱلْحَمْدُ لِلَّٰهِ")
                    .font(font)
                
                Text("ALHUMDULILLAH")
                    .foregroundStyle(Color.secondary)
                
                Text("Praise be to Allah")
            } else {
                Text("سُبْحَانَ ٱللَّٰهِ")
                    .font(font)
                
                Text("SUBHANALLAH")
                    .foregroundStyle(Color.secondary)
                
                Text("Glory be to Allah")
            }
        }
        .font(.system(size: 20))
        .multilineTextAlignment(.center)
        .lineSpacing(20)
    }
    
    private var reduceButton: some View {
        Button {
            reduceCounter()
        } label: {
            reduceButtonLabel
        }
    }
    
    private var reduceButtonLabel: some View {
        HStack {
            Image(systemName: "minus.circle")
            
            Text("Minus 1")
        }
        .font(.system(.headline, weight: .bold))
        .foregroundStyle(Color.primary)
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
    
    private func reduceCounter() {
        withAnimation(nil) {
            if count > 0 {
                count -= 1
            }
        }
    }
    
    private var resetButton: some View {
        Button(role: .destructive) {
            resetCounter()
        } label: {
            resetButtonLabel
        }
    }
    
    private var resetButtonLabel: some View {
        HStack {
            Image(systemName: "arrow.clockwise.circle")
            
            Text("Reset")
        }
        .font(.system(.headline, weight: .bold))
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
    
    private func resetCounter() {
        withAnimation(nil) {
            count = 0
        }
    }
}

extension AppDelegate {
    static var orientationLock = UIInterfaceOrientationMask.allButUpsideDown {
        didSet {
            UIApplication.shared.connectedScenes.forEach { scene in
                if let windowScene = scene as? UIWindowScene {
                    windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientationLock))
                }
            }
            
            UIApplication.shared.getWindow()?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

extension UIApplication {
    func getWindow() -> UIWindow? {
        guard let firstScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        guard let firstWindow = firstScene.windows.first else { return nil }
        return firstWindow
    }
}

#Preview {
    TasbeehView()
}
