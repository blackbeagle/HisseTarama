import Foundation
import SwiftUI
import Accelerate

struct Value:Decodable {
    
    let HGDG_HS_KODU:String?
    let HGDG_TARIH:String?
    let HGDG_KAPANIS:Double?
    let HGDG_AOF:Double?
    let HGDG_MIN:Double?
    let HGDG_MAX:Double?
    let HGDG_HACIM:Double?
    let END_ENDEKS_KODU:String?
    let END_TARIH:Double?
    let END_SEANS:Double?
    let END_DEGER: Double?
    let DD_DOVIZ_KODU: String?
    let DD_DT_KODU:String?
    let DD_TARIH: Double?
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

struct StockData:Decodable {

    let values:[Value]

}


