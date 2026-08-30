// IsYatirimService.swift

import Foundation

final class IsYatirimService {

    // MARK: - Singleton

    static let shared = IsYatirimService()

    // MARK: - Properties

    private let baseURL =
        "https://www.isyatirim.com.tr/_layouts/15/IsYatirim.Website/Common/Data.aspx/HisseTekil"

    private init() {}

    // MARK: - Currency

    enum PriceCurrency {
        case tryLira
        case usd
    }

    // MARK: - Fetch

    func fetchHisseVerileri(
        hisse: String,
        startDate: Date,
        endDate: Date,
        currency: PriceCurrency = .tryLira,
        completion: @escaping (Result<[Candlestick], Error>) -> Void
    ) {

        // -------------------------------------------------
        // Tarih formatı
        // -------------------------------------------------

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "tr_TR")
        dateFormatter.dateFormat = "dd-MM-yyyy"

        let startDateString =
            dateFormatter.string(from: startDate)

        let endDateString =
            dateFormatter.string(from: endDate)

        // -------------------------------------------------
        // URL
        // -------------------------------------------------

        var components =
            URLComponents(string: baseURL)

        components?.queryItems = [

            URLQueryItem(
                name: "hisse",
                value: hisse
            ),

            URLQueryItem(
                name: "startdate",
                value: startDateString
            ),

            URLQueryItem(
                name: "enddate",
                value: endDateString
            )
        ]

        guard let url = components?.url else {

            completion(
                .failure(
                    NSError(
                        domain: "IsYatirimService",
                        code: -1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Geçersiz URL oluşturuldu."
                        ]
                    )
                )
            )

            return
        }

        // -------------------------------------------------
        // Request
        // -------------------------------------------------

        let task =
            URLSession.shared.dataTask(
                with: url
            ) { [weak self] data, response, error in

                if let error = error {

                    completion(
                        .failure(error)
                    )

                    return
                }

                guard let httpResponse =
                        response as? HTTPURLResponse
                else {

                    completion(
                        .failure(
                            NSError(
                                domain: "IsYatirimService",
                                code: -2,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Sunucu yanıtı alınamadı."
                                ]
                            )
                        )
                    )

                    return
                }

                guard
                    200...299 ~= httpResponse.statusCode
                else {

                    completion(
                        .failure(
                            NSError(
                                domain: "IsYatirimService",
                                code: httpResponse.statusCode,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "İş Yatırım sunucusu HTTP \(httpResponse.statusCode) döndürdü."
                                ]
                            )
                        )
                    )

                    return
                }

                guard let data = data else {

                    completion(
                        .failure(
                            NSError(
                                domain: "IsYatirimService",
                                code: -3,
                                userInfo: [
                                    NSLocalizedDescriptionKey:
                                        "Sunucudan veri alınamadı."
                                ]
                            )
                        )
                    )

                    return
                }

                do {

                    let decoder =
                        JSONDecoder()

                    let response =
                        try decoder.decode(
                            IsYatirimResponse.self,
                            from: data
                        )

                    guard response.ok else {

                        let message =
                            response.errorDescription ??
                            "İş Yatırım veri servisi hata döndürdü."

                        completion(
                            .failure(
                                NSError(
                                    domain: "IsYatirimService",
                                    code: -4,
                                    userInfo: [
                                        NSLocalizedDescriptionKey:
                                            message
                                    ]
                                )
                            )
                        )

                        return
                    }

                    guard let self = self else {
                        return
                    }

                    let candlesticks =
                        self.convertToCandlesticks(
                            response.value
                        )

                    completion(
                        .success(candlesticks)
                    )

                } catch {

                    completion(
                        .failure(error)
                    )
                }
            }

        task.resume()
    }

    // MARK: - Convert API Data

    private func convertToCandlesticks(
        _ hisseVerileri: [HisseGunlukVeri]
    ) -> [Candlestick] {

        var candlesticks: [Candlestick] = []

        let dateFormatter =
            DateFormatter()

        dateFormatter.locale =
            Locale(identifier: "tr_TR")

        dateFormatter.dateFormat =
            "dd-MM-yyyy"

        for veri in hisseVerileri {

            guard let date =
                    dateFormatter.date(
                        from: veri.HGDG_TARIH
                    )
            else {
                continue
            }

            // -------------------------------------------------
            // TRY değerleri
            // -------------------------------------------------

            let tryMax =
                veri.HGDG_MAX

            let tryMin =
                veri.HGDG_MIN

            let tryAOF =
                veri.HGDG_AOF

            // -------------------------------------------------
            // USD değerleri
            // -------------------------------------------------
            //
            // İş Yatırım'ın doğrudan sağladığı USD değerleri
            // kullanılıyor.
            //
            // DOLAR_BAZLI_FIYAT kullanılmıyor.
            // Herhangi bir kur dönüşümü yapılmıyor.
            //
            // -------------------------------------------------

            let usdMax =
                veri.DOLAR_BAZLI_MAX

            let usdMin =
                veri.DOLAR_BAZLI_MIN

            let usdAOF =
                veri.DOLAR_BAZLI_AOF

            // -------------------------------------------------
            // Candlestick
            // -------------------------------------------------

         
            let candlestick = Candlestick(
                    max: tryMax,
                    min: tryMin,
                    weightedAverage: tryAOF,
                    date: date,
                    volume: veri.HGDG_HACIM,
                    usdVolume: veri.DOLAR_HACIM ?? 0,
                    usdMax: usdMax,
                    usdMin: usdMin,
                    usdWeightedAverage: usdAOF
            )

            
            candlesticks.append(
                candlestick
            )
        }

        // -------------------------------------------------
        // Kronolojik sıralama
        // -------------------------------------------------

        return candlesticks.sorted {
            $0.date < $1.date
        }
    }
}
