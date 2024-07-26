//
//  PrayerTimesModel.swift
//  Quran
//
//  Created by Ali Earp on 15/06/2024.
//

import Foundation
import Alamofire
import SwiftSoup

class PrayerTimesModel: ObservableObject {
    @Published var prayerTimes: [String : String] = [:]
    
    init() {
        fetchPrayerTimes { prayerTimes in
            if let prayerTimes = prayerTimes {
                self.prayerTimes = prayerTimes
            }
        }
    }
    
    func fetchPrayerTimes(completion: @escaping ([String: String]?) -> Void) {
        let url = "https://najaf.org/english/"

        AF.request(url).responseString { response in
            switch response.result {
            case .success(let html):
                if let document = try? SwiftSoup.parse(html),
                   let prayerTimeDiv = try? document.select("#prayer_time").first(),
                   let prayerItems = try? prayerTimeDiv.select("ul > li") {
                    var prayerTimes: [String : String] = [:]
                    
                    for item in prayerItems {
                        if let prayerName = try? item.text().letters,
                           let prayerTime = try? item.select("span").text() {
                            prayerTimes[prayerName] = prayerTime
                        }
                    }
                    
                    completion(prayerTimes)
                }
            case .failure(_):
                completion(nil)
            }
        }
    }
}

extension String {
    var letters: String {
        return String(unicodeScalars.filter(CharacterSet.letters.contains))
    }
}
