import Foundation

final class FinancialDataService {

    // MARK: - Singleton

    static let shared = FinancialDataService()

    private init() {}

    // MARK: - Constants

    private let baseURL =
        "https://www.isyatirim.com.tr/_layouts/15/IsYatirim.Website/Common/Data.aspx/MaliTablo"

    private let defaultQuarterCount = 10

    private let financialGroup = "XI_29"

    // İş Yatırım MaliTablo endpoint'i bir sorguda
    // 4 periyot kullanacak şekilde çalışıyor.
    private let maximumPeriodsPerRequest = 4

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
                .uppercased()

        guard !normalizedCompanyCode.isEmpty else {
            completion(
                .failure(
                    makeError(
                        code: -1,
                        message: "Şirket kodu boş olamaz."
                    )
                )
            )
            return
        }

        let quarterCount =
            max(
                1,
                query.financialQuarterCount
                    ?? defaultQuarterCount
            )

        /*
         -----------------------------------------------------
         Son bilanço dönemi
         -----------------------------------------------------

         Kullanıcı bir dönem verdiyse onu kullanıyoruz.

         nil ise API üzerinden otomatik keşif yapıyoruz.
         -----------------------------------------------------
         */

        if let lastPeriod = query.lastFinancialPeriod {

            print(
                "Finansal veri sorgusu kullanıcı tarafından belirlenen dönemden başlıyor: \(lastPeriod.title)"
            )

            fetchPeriods(
                companyCode: normalizedCompanyCode,
                lastPeriod: lastPeriod,
                quarterCount: quarterCount,
                currency: query.currency,
                completion: completion
            )

        } else {

            print("Finansal dönem keşfi başladı.")

            discoverLastPublishedPeriod(
                companyCode: normalizedCompanyCode,
                currency: query.currency
            ) { [weak self] result in

                guard let self = self else {
                    return
                }

                switch result {

                case .success(let lastPeriod):

                    print(
                        "Yayınlanmış son bilanço: \(lastPeriod.title)"
                    )

                    self.fetchPeriods(
                        companyCode:
                            normalizedCompanyCode,
                        lastPeriod:
                            lastPeriod,
                        quarterCount:
                            quarterCount,
                        currency:
                            query.currency,
                        completion:
                            completion
                    )

                case .failure(let error):

                    completion(
                        .failure(error)
                    )
                }
            }
        }
    }

    // MARK: - Discover Last Published Period

    private func discoverLastPublishedPeriod(
        companyCode: String,
        currency: StockCurrency,
        completion: @escaping (
            Result<FinancialPeriod, Error>
        ) -> Void
    ) {

        let firstCandidate =
            makeInitialCandidatePeriod()

        print(
            "İlk aday dönem: \(firstCandidate.title)"
        )

        checkCandidatePeriod(
            companyCode: companyCode,
            period: firstCandidate,
            currency: currency,
            completion: completion
        )
    }

    // MARK: - Initial Candidate

    private func makeInitialCandidatePeriod()
        -> FinancialPeriod
    {
        let calendar =
            Calendar.current

        let now =
            Date()

        let year =
            calendar.component(
                .year,
                from: now
            )

        let month =
            calendar.component(
                .month,
                from: now
            )

        /*
         -----------------------------------------------------
         Tamamlanmış son çeyrek
         -----------------------------------------------------

         Ocak - Mart     -> önceki yıl Q4
         Nisan - Haziran -> Q1
         Temmuz - Eylül  -> Q2
         Ekim - Aralık   -> Q3

         Örneğin:
         Ağustos 2026 -> 2026 Q2
         -----------------------------------------------------
         */

        let currentQuarter =
            ((month - 1) / 3) + 1

        var completedQuarter =
            currentQuarter - 1

        var completedYear =
            year

        if completedQuarter == 0 {
            completedQuarter = 4
            completedYear -= 1
        }

        return FinancialPeriod(
            year: completedYear,
            quarter: completedQuarter
        )
    }

    // MARK: - Check Candidate

    private func checkCandidatePeriod(
        companyCode: String,
        period: FinancialPeriod,
        currency: StockCurrency,
        completion: @escaping (
            Result<FinancialPeriod, Error>
        ) -> Void
    ) {

        print(
            "Finansal dönem kontrol ediliyor: \(period.title)"
        )

        /*
         -----------------------------------------------------
         ÖNEMLİ

         API'nin çalışan formatına göre aynı dönem
         dört kez gönderiliyor.

         Örneğin:

         year1=2026&period1=6
         year2=2026&period2=6
         year3=2026&period3=6
         year4=2026&period4=6

         -----------------------------------------------------
         */

        let periods = Array(
            repeating: period,
            count: maximumPeriodsPerRequest
        )

        guard let url =
                makeURL(
                    companyCode:
                        companyCode,
                    periods:
                        periods,
                    currency:
                        currency
                )
        else {

            completion(
                .failure(
                    makeError(
                        code: -10,
                        message:
                            "Finansal dönem kontrol URL'si oluşturulamadı."
                    )
                )
            )

            return
        }

        print(
            "Dönem kontrol URL: \(url.absoluteString)"
        )

        var request =
            URLRequest(
                url: url
            )

        request.httpMethod = "GET"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        let task =
            URLSession.shared.dataTask(
                with: request
            ) { [weak self] data, response, error in

                guard let self = self else {
                    return
                }

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
                            self.makeError(
                                code: -11,
                                message:
                                    "Finansal dönem kontrolünde sunucu yanıtı alınamadı."
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
                                code: -12,
                                message:
                                    "Finansal dönem kontrolünde veri alınamadı."
                            )
                        )
                    )

                    return
                }

                do {

                    let hasData =
                        try self.responseContainsFinancialData(
                            data: data
                        )

                    if hasData {

                        print(
                            "\(period.title) için veri bulundu."
                        )

                        print(
                            "Yayınlanmış son bilanço bulundu: \(period.title)"
                        )

                        completion(
                            .success(period)
                        )

                    } else {

                        print(
                            "\(period.title) için veri yok."
                        )

                        let previousPeriod =
                            self.previousPeriod(
                                from: period
                            )

                        print(
                            "Bir önceki dönem deneniyor: \(previousPeriod.title)"
                        )

                        self.checkCandidatePeriod(
                            companyCode:
                                companyCode,
                            period:
                                previousPeriod,
                            currency:
                                currency,
                            completion:
                                completion
                        )
                    }

                } catch {

                    completion(
                        .failure(error)
                    )
                }
            }

        task.resume()
    }

    // MARK: - Fetch Periods

    private func fetchPeriods(
        companyCode: String,
        lastPeriod: FinancialPeriod,
        quarterCount: Int,
        currency: StockCurrency,
        completion: @escaping (
            Result<FinancialStatements, Error>
        ) -> Void
    ) {

        let periods =
            makeQuarterPeriods(
                endingAt:
                    lastPeriod,
                count:
                    quarterCount
            )

        guard !periods.isEmpty else {

            completion(
                .failure(
                    makeError(
                        code: -20,
                        message:
                            "Finansal dönem listesi oluşturulamadı."
                    )
                )
            )

            return
        }

        /*
         ---------------------------------------------------------
         API 4 dönemlik bloklar halinde çağrılıyor.

         Örneğin 10 dönem:

         4 dönem
         4 dönem
         2 dönem
         ---------------------------------------------------------
         */

        var chunks: [[FinancialPeriod]] = []

        var startIndex = 0

        while startIndex < periods.count {

            let endIndex =
                min(
                    startIndex + maximumPeriodsPerRequest,
                    periods.count
                )

            let chunk =
                Array(
                    periods[startIndex..<endIndex]
                )

            chunks.append(chunk)

            startIndex = endIndex
        }

        fetchPeriodChunks(
            companyCode:
                companyCode,
            chunks:
                chunks,
            chunkIndex:
                0,
            currency:
                currency,
            allPeriods:
                periods,
            completion:
                completion
        )
    }
    // MARK: - Fetch Chunks

    private func fetchPeriodChunks(
        companyCode: String,
        chunks: [[FinancialPeriod]],
        chunkIndex: Int,
        currency: StockCurrency,
        allPeriods: [FinancialPeriod],
        completion: @escaping (
            Result<FinancialStatements, Error>
        ) -> Void
    ) {

        if chunkIndex >= chunks.count {

            /*
             -------------------------------------------------
             Şimdilik gerçek finansal kalem parser'ı
             mevcut FinancialStatements yapısına
             ayrı aşamada bağlanacak.

             -------------------------------------------------
             */

            completion(
                .success(
                    FinancialStatements(
                        periods:
                            allPeriods,
                        items:
                            [:]
                    )
                )
            )

            return
        }

        let chunk =
            chunks[chunkIndex]

        guard let url =
                makeURL(
                    companyCode:
                        companyCode,
                    periods:
                        chunk,
                    currency:
                        currency
                )
        else {

            completion(
                .failure(
                    makeError(
                        code: -21,
                        message:
                            "Finansal veri URL'si oluşturulamadı."
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
                url:
                    url
            )

        request.httpMethod =
            "GET"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Accept"
        )

        let task =
            URLSession.shared.dataTask(
                with:
                    request
            ) { [weak self] data, response, error in

                guard let self = self else {
                    return
                }

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
                            self.makeError(
                                code: -22,
                                message:
                                    "Finansal veri sunucu yanıtı alınamadı."
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
                                code: -23,
                                message:
                                    "Finansal veri alınamadı."
                            )
                        )
                    )

                    return
                }

                do {

                    /*
                     -------------------------------------------------
                     JSON'u şimdilik doğruluyoruz.

                     Gerçek FinancialStatements parser'ı
                     daha sonra burada geliştirilecek.
                     -------------------------------------------------
                     */

                    _ =
                        try self.responseContainsFinancialData(
                            data:
                                data
                        )

                    self.fetchPeriodChunks(
                        companyCode:
                            companyCode,
                        chunks:
                            chunks,
                        chunkIndex:
                            chunkIndex + 1,
                        currency:
                            currency,
                        allPeriods:
                            allPeriods,
                        completion:
                            completion
                    )

                } catch {

                    completion(
                        .failure(error)
                    )
                }
            }

        task.resume()
    }

    // MARK: - Quarter Periods

    private func makeQuarterPeriods(
        endingAt lastPeriod: FinancialPeriod,
        count: Int
    ) -> [FinancialPeriod] {

        let requestedCount =
            max(
                1,
                count
            )

        var periods:
            [FinancialPeriod] = []

        var year =
            lastPeriod.year

        var quarter =
            lastPeriod.quarter

        for _ in 0..<requestedCount {

            periods.append(
                FinancialPeriod(
                    year:
                        year,
                    quarter:
                        quarter
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

    // MARK: - Previous Period

    private func previousPeriod(
        from period: FinancialPeriod
    ) -> FinancialPeriod {

        if period.quarter > 1 {

            return FinancialPeriod(
                year:
                    period.year,
                quarter:
                    period.quarter - 1
            )

        } else {

            return FinancialPeriod(
                year:
                    period.year - 1,
                quarter:
                    4
            )
        }
    }

    // MARK: - API Period Value

    private func apiPeriodValue(
        for quarter: Int
    ) -> Int {

        switch quarter {

        case 1:
            return 3

        case 2:
            return 6

        case 3:
            return 9

        case 4:
            return 12

        default:
            return 0
        }
    }

    // MARK: - URL

    private func makeURL(
        companyCode: String,
        periods: [FinancialPeriod],
        currency: StockCurrency
    ) -> URL? {

        guard !periods.isEmpty else {
            return nil
        }

        var components =
            URLComponents(
                string:
                    baseURL
            )

        var queryItems:
            [URLQueryItem] = [

                URLQueryItem(
                    name:
                        "companyCode",
                    value:
                        companyCode
                ),

                URLQueryItem(
                    name:
                        "exchange",
                    value:
                        currency.apiValue
                ),

                URLQueryItem(
                    name:
                        "financialGroup",
                    value:
                        financialGroup
                )
            ]

        for (index, period)
            in periods.enumerated()
        {

            let number =
                index + 1

            let apiPeriod =
                apiPeriodValue(
                    for:
                        period.quarter
                )

            guard apiPeriod > 0 else {
                continue
            }

            queryItems.append(
                URLQueryItem(
                    name:
                        "year\(number)",
                    value:
                        String(
                            period.year
                        )
                )
            )

            queryItems.append(
                URLQueryItem(
                    name:
                        "period\(number)",
                    value:
                        String(
                            apiPeriod
                        )
                )
            )
        }

        /*
         -----------------------------------------------------
         Eğer 4'ten az dönem gönderiyorsak,
         API'nin çalışan yapısını korumak için
         son dönemi 4'e tamamlıyoruz.

         Örneğin tek dönem:

         year1=2026&period1=6
         year2=2026&period2=6
         year3=2026&period3=6
         year4=2026&period4=6

         -----------------------------------------------------
         */

        if periods.count < maximumPeriodsPerRequest {

            let fillPeriod =
                periods.last!

            let fillAPIValue =
                apiPeriodValue(
                    for:
                        fillPeriod.quarter
                )

            if fillAPIValue > 0 {

                for index
                    in periods.count..<maximumPeriodsPerRequest
                {

                    let number =
                        index + 1

                    queryItems.append(
                        URLQueryItem(
                            name:
                                "year\(number)",
                            value:
                                String(
                                    fillPeriod.year
                                )
                        )
                    )

                    queryItems.append(
                        URLQueryItem(
                            name:
                                "period\(number)",
                            value:
                                String(
                                    fillAPIValue
                                )
                        )
                    )
                }
            }
        }

        components?.queryItems =
            queryItems

        return components?.url
    }

    // MARK: - Response Validation

    private func responseContainsFinancialData(
        data: Data
    ) throws -> Bool {

        guard
            let jsonObject =
                try JSONSerialization.jsonObject(
                    with:
                        data,
                    options:
                        []
                ) as? [String: Any]
        else {

            throw makeError(
                code:
                    -30,
                message:
                    "Finansal veri JSON formatında okunamadı."
            )
        }

        if let ok =
            jsonObject["ok"] as? Bool,
            !ok
        {

            let message =
                jsonObject[
                    "errorDescription"
                ] as? String
                ??
                "İş Yatırım finansal veri servisi hata döndürdü."

            throw makeError(
                code:
                    -31,
                message:
                    message
            )
        }

        guard let value =
                jsonObject["value"]
        else {

            return false
        }

        if let array =
            value as? [Any]
        {

            return !array.isEmpty
        }

        return false
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
            userInfo:
                [
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
                    nil,
                financialQuarterCount:
                    10,
                currency:
                    .tryCurrency
            )

        fetchFinancialStatements(
            companyCode:
                "SISE",
            query:
                query
        ) { result in

            switch result {

            case .success(let statements):

                print(
                    "================================"
                )

                print(
                    "FİNANSAL VERİ TESTİ BAŞARILI"
                )

                print(
                    "================================"
                )

                print(
                    "Dönem sayısı: \(statements.periods.count)"
                )

                for period
                    in statements.periods
                {

                    print(
                        "Dönem: \(period.title)"
                    )
                }

            case .failure(let error):

                print(
                    "================================"
                )

                print(
                    "FİNANSAL VERİ TESTİ HATALI"
                )

                print(
                    "================================"
                )

                print(
                    "Hata: \(error.localizedDescription)"
                )
            }
        }
    }
}
