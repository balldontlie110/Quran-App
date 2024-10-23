//
//  ZiyaratView.swift
//  Quran
//
//  Created by Ali Earp on 19/07/2024.
//

import SwiftUI

struct ZiyaratView: View {
    let ziyarat: Ziyarat
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(ziyarat.verses) { verse in
                    VStack(spacing: 0) {
                        VStack(spacing: 15) {
                            let fontNumber = UserDefaultsController.shared.integer(forKey: "fontNumber")
                            
                            let defaultFont = Font.system(size: CGFloat(UserDefaultsController.shared.double(forKey: "fontSize")), weight: .bold)
                            let uthmanicFont = Font.custom("KFGQPCUthmanicScriptHAFS", size: CGFloat(UserDefaultsController.shared.double(forKey: "fontSize")))
                            let notoNastaliqFont = Font.custom("NotoNastaliqUrdu", size: CGFloat(UserDefaultsController.shared.double(forKey: "fontSize")))
                            
                            let font = fontNumber == 1 ? defaultFont : fontNumber == 2 ? uthmanicFont : notoNastaliqFont
                            
                            Text(verse.text)
                                .font(font)
                                .multilineTextAlignment(.center)
                                .lineSpacing(20)
                            
                            Text(verse.transliteration.uppercased())
                                .font(.system(size: 20))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.secondary)
                            
                            Text(verse.translation)
                                .font(.system(size: 20))
                                .multilineTextAlignment(.center)
                        }.padding(.vertical)
                        
                        if verse.id != ziyarat.verses.count {
                            if verse.gap {
                                Spacer()
                                    .frame(height: 50)
                            } else {
                                Divider()
                            }
                        }
                    }
                }
            }.padding(.horizontal, 10)
        }
        .navigationTitle(ziyarat.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            DispatchQueue.main.async {
                AppDelegate.orientationLock = UIInterfaceOrientationMask.allButUpsideDown
            }
        }.onDisappear {
            DispatchQueue.main.async {
                AppDelegate.orientationLock = UIInterfaceOrientationMask.portrait
            }
        }
    }
}

#Preview {
    ZiyaratView(ziyarat: Ziyarat(id: 0, title: "", subtitle: nil, verses: []))
}
