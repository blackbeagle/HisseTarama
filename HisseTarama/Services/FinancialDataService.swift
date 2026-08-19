import Foundation

final class FinancialDataService {

    // MARK: - Singleton

    static let shared = FinancialDataService()

    private init() {}

    // MARK: - Constants

    private let baseURL =
        "https://www.isyatirim.com.tr/_layouts/15/IsYatirim.Website/Common/Data.aspx/MaliTablo"

    // MARK: - Configuration

    private let defaultQuarterCount = 10

    private let financialGroup = "XI_29"

    // MARK: - Public Fetch

    func fetchFinancialStatements(
        companyCode: String,
        query: StockDataQuery,
        completion: @escaping (
            Result<FinancialStatements, Error>
        ) -> Void
    ) {

        let normalizedCompanyCode =
            companyCode
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .lowercased()

        guard !normalizedCompanyCode.isEmpty else {
            completion(
                .failure(
                    makeError(
                        code: -1,
                        message:
                            "Şirket kodu boş olamaz."
                    )
                )
            )
            return
        }

        // -------------------------------------------------
        // Dönem sayısı
        // -------------------------------------------------

        let requestedQuarterCount =
            max(
                1,
                query.financialQuarterCount
                    ?? defaultQuarterCount
            )

        // -------------------------------------------------
        // Kullanıcının belirlediği son dönemden geriye doğru
        // finansal dönemleri oluştur.
        // -------------------------------------------------

        let periods =
            makeQuarterPeriods(
                lastPeriod:
                    query.lastFinancialPeriod,
                count:
                    requestedQuarterCount
            )

        guard !periods.isEmpty else {
            completion(
                .failure(
                    makeError(
                        code: -2,
                        message:
                            "Finansal dönem oluşturulamadı."
                    )
                )
            )
            return
        }

        // -------------------------------------------------
        // URL
        // -------------------------------------------------

        guard let url =
                makeURL(
                    companyCode:
                        normalizedCompanyCode,
                    periods:
                        periods,
                    currency:
                        query.currency
                )
        else {
            completion(
                .failure(
                    makeError(
                        code: -3,
                        message:
                            "Geçersiz finansal veri URL'si oluşturuldu."
                    )
                )
            )
            return
        }

        print(
            "Finansal veri URL: \(url.absoluteString)"
        )

        var request =
            URLRequest(
                url: url
            )

        request.httpMethod = "GET"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Accept"
        )

        // -------------------------------------------------
        // Request
        // -------------------------------------------------

        let task =
            URLSession.shared.dataTask(
                with: request
            ) { [weak self] data, response, error in

                if let error = error {
                    completion(
                        .failure(error)
                    )
                    return
                }

                guard let self = self else {
                    return
                }

                guard let httpResponse =
                        response as? HTTPURLResponse
                else {
                    completion(
                        .failure(
                            self.makeError(
                                code: -4,
                                message:
                                    "Sunucu yanıtı alınamadı."
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
                            self.makeError(
                                code:
                                    httpResponse.statusCode,
                                message:
                                    "İş Yatırım sunucusu HTTP \(httpResponse.statusCode) döndürdü."
                            )
                        )
                    )
                    return
                }

                guard let data = data else {
                    completion(
                        .failure(
                            self.makeError(
                                code: -5,
                                message:
                                    "Sunucudan finansal veri alınamadı."
                            )
                        )
                    )
                    return
                }

                do {

                    let statements =
                        try self.parseFinancialStatements(
                            data: data,
                            periods: periods
                        )

                    completion(
                        .success(
                            statements
                        )
                    )

                } catch {

                    print(
                        "FinancialDataService parse hatası: \(error)"
                    )

                    completion(
                        .failure(error)
                    )
                }
            }

        task.resume()
    }

    // MARK: - Quarter Periods

    private func makeQuarterPeriods(
        lastPeriod: FinancialPeriod,
        count: Int
    ) -> [FinancialPeriod] {

        var year =
            lastPeriod.year

        var quarter =
            lastPeriod.quarter

        var periods:
            [FinancialPeriod] = []

        for _ in 0..<count {

            periods.append(
                FinancialPeriod(
                    year: year,
                    quarter: quarter
                )
            )

            quarter -= 1

            if quarter == 0 {
                quarter = 4
                year -= 1
            }
        }

        return periods
    }

    // MARK: - URL

    private func makeURL(
        companyCode: String,
        periods: [FinancialPeriod],
        currency: StockCurrency
    ) -> URL? {

        var components =
            URLComponents(
                string: baseURL
            )

        var queryItems:
            [URLQueryItem] = [

                URLQueryItem(
                    name: "companyCode",
                    value: companyCode
                ),

                URLQueryItem(
                    name: "exchange",
                    value: currency.rawValue
                ),

                URLQueryItem(
                    name: "financialGroup",
                    value: financialGroup
                )
            ]

        for (index, period)
            in periods.enumerated() {

            let number =
                index + 1

            queryItems.append(
                URLQueryItem(
                    name:
                        "year\(number)",
                    value:
                        String(period.year)
                )
            )

            queryItems.append(
                URLQueryItem(
                    name:
                        "period\(number)",
                    value:
                        String(period.quarter)
                )
            )
        }

        components?.queryItems =
            queryItems

        return components?.url
    }

    // MARK: - Parse

    private func parseFinancialStatements(
        data: Data,
        periods: [FinancialPeriod]
    ) throws -> FinancialStatements {

        print("MaliTablo JSON:")

        print(
            String(
                data: data,
                encoding: .utf8
            ) ?? "JSON okunamadı"
        )

        guard
            let jsonObject =
                try JSONSerialization.jsonObject(
                    with: data,
                    options: []
                ) as? [String: Any]
        else {
            throw makeError(
                code: -6,
                message:
                    "Finansal veri JSON formatında okunamadı."
            )
        }

        // -------------------------------------------------
        // API başarı kontrolü
        // -------------------------------------------------

        if let ok =
            jsonObject["ok"] as? Bool,
            !ok {

            let message =
                jsonObject[
                    "errorDescription"
                ] as? String
                ??
                "İş Yatırım finansal veri servisi hata döndürdü."

            throw makeError(
                code: -7,
                message: message
            )
        }

        // -------------------------------------------------
        // Şimdilik JSON doğrulaması
        // -------------------------------------------------

        return FinancialStatements(
            periods: periods,
            items: [:]
        )
    }

    // MARK: - Error

    private func makeError(
        code: Int,
        message: String
    ) -> NSError {

        NSError(
            domain:
                "FinancialDataService",
            code:
                code,
            userInfo: [
                NSLocalizedDescriptionKey:
                    message
            ]
        )
    }

    // MARK: - Temporary Test

    func testFetch() {

        let query =
            StockDataQuery(
                lastFinancialPeriod:
                    FinancialPeriod(
                        year: 2026,
                        quarter: 2
                    ),
                financialQuarterCount:
                    10,
                currency:
                    .tryCurrency
            )

        fetchFinancialStatements(
            companyCode: "SISE",
            query: query
        ) { result in

            switch result {

            case .success(let statements):

                print("================================")
                print("FINANSAL VERİ TESTİ BAŞARILI")
                print("================================")

                print(
                    "Dönem sayısı: \(statements.periods.count)"
                )

                for period in statements.periods {

                    print(
                        "Dönem: \(period.title)"
                    )
                }

            case .failure(let error):

                print("================================")
                print("FINANSAL VERİ TESTİ HATALI")
                print("================================")

                print(
                    "Hata: \(error.localizedDescription)"
                )
            }
        }
    }
}
