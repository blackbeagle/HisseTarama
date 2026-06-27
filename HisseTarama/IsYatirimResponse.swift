// IsYatirimResponse.swift
import Foundation

// API'den gelen ana response yapısı
struct IsYatirimResponse: Codable {
    let ok: Bool
    let errorCode: String?
    let errorDescription: String?
    let transactionId: String?
    let value: [HisseGunlukVeri]
}

// Her bir günlük hisse verisi
struct HisseGunlukVeri: Codable {
    let HGDG_HS_KODU: String      // Hisse kodu
    let HGDG_TARIH: String        // Tarih (dd-MM-yyyy)
    let HGDG_KAPANIS: Double      // Kapanış fiyatı
    let HGDG_AOF: Double          // Ağırlıklı ortalama fiyat
    let HGDG_MIN: Double          // Minimum fiyat
    let HGDG_MAX: Double          // Maksimum fiyat
    let HGDG_HACIM: Double        // Hacim
    
    // Diğer alanlar opsiyonel (ihtiyaca göre eklenebilir)
    let END_ENDEKS_KODU: String?
    let END_TARIH: Int64?
    let END_SEANS: Int?
    let END_DEGER: Double?
    let DD_DOVIZ_KODU: String?
    let DD_DT_KODU: String?
    let DD_TARIH: Int64?
    let DD_DEGER: Double?
    let DOLAR_BAZLI_FIYAT: Double?
    let ENDEKS_BAZLI_FIYAT: Double?
    let DOLAR_HACIM: Double?
    let SERMAYE: Double?
    let HG_KAPANIS: Double?
    let HG_AOF: Double?
    let HG_MIN: Double?
    let HG_MAX: Double?
    let PD: Double?
    let PD_USD: Double?
    let HAO_PD: Double?
    let HAO_PD_USD: Double?
    let HG_HACIM: Double?
    let DOLAR_BAZLI_MIN: Double?
    let DOLAR_BAZLI_MAX: Double?
    let DOLAR_BAZLI_AOF: Double?
}

// Hisse isteği için parametreler
struct HisseTekilRequest {
    let hisse: String
    let startDate: String  // dd-MM-yyyy formatında
    let endDate: String    // dd-MM-yyyy formatında
}
