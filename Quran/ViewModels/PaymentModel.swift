//
//  PaymentModel.swift
//  Quran
//
//  Created by Ali Earp on 19/07/2024.
//

import Foundation
import StripePaymentSheet
import LocalAuthentication

class PaymentModel: ObservableObject {
    @Published var paymentSheet: PaymentSheet = PaymentSheet(paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration())
    @Published var paymentResult: PaymentSheetResult?
    
    @Published var showPaymentSheet: Bool = false
    @Published var isLoading: Bool = false
    
    @Published var donation: String = "10"
    
    func preparePaymentSheet() {
        self.isLoading = true
        
        if let url = URL(string: "https://mewing-bittersweet-mousepad.glitch.me/payment-sheet"), let amount = Double(donation) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(Donation(amount: amount))
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {
                    self.isLoading = false
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                      let customerId = json["customer"] as? String,
                      let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                      let paymentIntentClientSecret = json["paymentIntent"] as? String,
                      let publishableKey = json["publishableKey"] as? String
                else {
                    self.isLoading = false
                    return
                }
                
                STPAPIClient.shared.publishableKey = publishableKey
                
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Quran"
                configuration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
                configuration.returnURL = "Quran://stripe-redirect"
                
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                
                self.authenticate { authenticated in
                    if authenticated {
                        DispatchQueue.main.async {
                            self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: configuration)
                            self.showPaymentSheet = true
                        }
                    }
                }
            }.resume()
        } else {
            self.isLoading = false
        }
    }
    
    func onPaymentCompletion(result: PaymentSheetResult) {
        self.paymentResult = result
    }
    
    func authenticate(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "We need to verify it's really you to make a donation."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                if success {
                    completion(true)
                }
            }
        }
    }
}

struct Donation: Encodable {
    let amount: Double
}
