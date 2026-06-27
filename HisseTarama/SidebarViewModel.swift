// SidebarViewModel.swift
import Foundation

struct SidebarItem {
    let name: String
    let children: [SidebarItem]?
}

class SidebarViewModel {
    
    let items: [SidebarItem] = [
        SidebarItem(name: "Teknik", children: [
            SidebarItem(name: "Teknik Analiz", children: nil),
            SidebarItem(name: "Teknik Tarama", children: nil)
            //SidebarItem(name: "GOOGL", children: nil)
        ]),
        SidebarItem(name: "Temel", children: [
            SidebarItem(name: "Temel Analiz", children: nil),
            SidebarItem(name: "Temel Tarama", children: nil)
        ])
        
    ]
}
