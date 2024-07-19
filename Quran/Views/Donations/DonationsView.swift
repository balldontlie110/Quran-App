//
//  DonationsView.swift
//  Quran

//  Created by Ali Earp on 19/07/2024.
//

import SwiftUI
import Combine
import StripePaymentSheet

struct DonationsView: View {
    @StateObject var paymentModel: PaymentModel = PaymentModel()
    
    private let columns: [GridItem] = [GridItem](repeating: GridItem(.flexible()), count: 5)
    private let predefinedAmounts = ["10", "25", "50", "100", "250"]
    
    var body: some View {
        Group {
            VStack(spacing: 50) {
                VStack(spacing: 25) {
                    donationField
                    
                    predefinedAmountsButtons
                }
                
                donateButton
                
                Spacer()
                
                if paymentModel.isLoading {
                    ProgressView()
                }
                
                Spacer()
            }.padding()
        }
        .navigationTitle("Donations")
        .navigationBarTitleDisplayMode(.inline)
        .paymentSheet(isPresented: $paymentModel.showPaymentSheet, paymentSheet: paymentModel.paymentSheet, onCompletion: paymentModel.onPaymentCompletion)
    }
    
    private var donationField: some View {
        HStack(spacing: 20) {
            Text("£")
            
            TextField("", text: $paymentModel.donation)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding(5)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .onReceive(Just(paymentModel.donation)) { newValue in
                    let filtered = newValue.filter { $0.isNumber }
                    
                    if filtered != newValue {
                        paymentModel.donation = filtered
                    }
                }
        }
        .font(.system(.title, weight: .bold))
        .padding(.horizontal, 50)
    }
    
    private var predefinedAmountsButtons: some View {
        LazyVGrid(columns: columns) {
            ForEach(predefinedAmounts, id: \.self) { amount in
                Button {
                    paymentModel.donation = amount
                } label: {
                    Text("£\(amount)")
                        .frame(maxWidth: .infinity)
                }.buttonStyle(BorderedButtonStyle())
            }
        }
    }
    
    private var donateButton: some View {
        Button {
            paymentModel.preparePaymentSheet()
        } label: {
            Text("Donate")
                .bold()
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
        }
    }
}

#Preview {
    DonationsView()
}
