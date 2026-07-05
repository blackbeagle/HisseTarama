// IsYatirimService.swift
import Foundation

class IsYatirimService {
    
    static let shared = IsYatirimService()
    private let baseURL = "https://www.isyatirim.com.tr/_layouts/15/Isyatirim.Website/Common/Data.aspx/HisseTekil"
    
    private init() {}
    
    func fetchHisseVerileri(
        hisse: String,
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<[Candlestick], Error>) -> Void
    ) {
        // Tarihleri formatla (dd-MM-yyyy)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        // URL oluştur
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "hisse", value: hisse),
            URLQueryItem(name: "startdate", value: startDateString),
            URLQueryItem(name: "enddate", value: endDateString)
        ]
        
        guard let url = components?.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        // URLSession ile veri çek
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2)))
                return
            }
            
            do {
                // JSON'u decode et
                let decoder = JSONDecoder()
                let response = try decoder.decode(IsYatirimResponse.self, from: data)
                
                // API başarılı mı kontrol et
                guard response.ok else {
                    let errorMsg = response.errorDescription ?? "Unknown error"
                    completion(.failure(NSError(domain: errorMsg, code: -3)))
                    return
                }
                
                // Hisse verilerini Candlestick formatına çevir
                let candlesticks = self.convertToCandlesticks(response.value)
                completion(.success(candlesticks))
                
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private func convertToCandlesticks(_ hisseVerileri: [HisseGunlukVeri]) -> [Candlestick] {
        var candlesticks: [Candlestick] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        
        for veri in hisseVerileri {
            // Tarih string'ini Date'e çevir
            if let date = dateFormatter.date(from: veri.HGDG_TARIH) {
                let stick = Candlestick(
                    max: veri.HGDG_MAX,
                    min: veri.HGDG_MIN,
                    weightedAverage: veri.HGDG_AOF,
                    date: date
                )
                candlesticks.append(stick)
            }
        }
        
        // Tarihe göre sırala (artandan azalana)
        return candlesticks.sorted { $0.date < $1.date }
    }
}
