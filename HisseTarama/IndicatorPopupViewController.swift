// IndicatorPopupViewController.swift
import Cocoa

protocol IndicatorPopupDelegate: AnyObject {
    func didSelectIndicators(selectedSMAs: [Int])
}

class IndicatorPopupViewController: NSViewController {
    
    // MARK: - Properties
    weak var delegate: IndicatorPopupDelegate?
    
    // Hızlı seçim için SMA periyotları
    private let quickSMAPeriods = [5, 8, 13, 21, 34,225]
    private var selectedSMAs: Set<Int> = []
    
    // MARK: - UI Elements
    private let titleLabel = NSTextField(labelWithString: "Gösterge ve Ortalama Ekle")
    private let smaSectionLabel = NSTextField(labelWithString: "Hareketli Ortalamalar (SMA)")
    private let customPeriodTextField = NSTextField()
    private let addCustomButton = NSButton()
    private let confirmButton = NSButton()
    private let cancelButton = NSButton()
    private var checkboxes: [NSButton] = []
    
    // MARK: - Lifecycle
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Title
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // SMA Section Label
        smaSectionLabel.font = NSFont.systemFont(ofSize: 12)
        smaSectionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(smaSectionLabel)
        
        // Hızlı SMA seçenekleri (checkbox'lar)
        var previousCheckbox: NSButton?
        for (index, period) in quickSMAPeriods.enumerated() {
            let checkbox = NSButton()
            checkbox.title = "SMA \(period)"
            checkbox.setButtonType(.switch)
            checkbox.target = self
            checkbox.action = #selector(smaCheckboxToggled(_:))
            checkbox.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(checkbox)
            checkboxes.append(checkbox)
            
            let row = index / 2
            let col = index % 2
            
            NSLayoutConstraint.activate([
                checkbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20 + CGFloat(col) * 140),
                checkbox.topAnchor.constraint(equalTo: smaSectionLabel.bottomAnchor, constant: 10 + CGFloat(row) * 30)
            ])
            previousCheckbox = checkbox
        }
        
        // Custom period input
        customPeriodTextField.placeholderString = "Özel periyot..."
        customPeriodTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customPeriodTextField)
        
        addCustomButton.title = "Ekle"
        addCustomButton.bezelStyle = .rounded
        addCustomButton.target = self
        addCustomButton.action = #selector(addCustomPeriod)
        addCustomButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addCustomButton)
        
        // Buttons
        confirmButton.title = "Uygula"
        confirmButton.bezelStyle = .rounded
        confirmButton.target = self
        confirmButton.action = #selector(confirmSelection)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(confirmButton)
        
        cancelButton.title = "İptal"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelSelection)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        // Layout
        let lastCheckboxY = (checkboxes.count / 2 + (checkboxes.count % 2 == 0 ? 0 : 1)) * 30 + 10
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            smaSectionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            smaSectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            customPeriodTextField.topAnchor.constraint(equalTo: smaSectionLabel.bottomAnchor, constant: CGFloat(lastCheckboxY + 20)),
            customPeriodTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customPeriodTextField.widthAnchor.constraint(equalToConstant: 150),
            
            addCustomButton.leadingAnchor.constraint(equalTo: customPeriodTextField.trailingAnchor, constant: 8),
            addCustomButton.centerYAnchor.constraint(equalTo: customPeriodTextField.centerYAnchor),
            
            confirmButton.topAnchor.constraint(equalTo: customPeriodTextField.bottomAnchor, constant: 30),
            confirmButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            confirmButton.widthAnchor.constraint(equalToConstant: 80),
            
            cancelButton.topAnchor.constraint(equalTo: customPeriodTextField.bottomAnchor, constant: 30),
            cancelButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            cancelButton.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    // MARK: - Actions
    @objc private func smaCheckboxToggled(_ sender: NSButton) {
        guard let index = checkboxes.firstIndex(of: sender) else { return }
        let period = quickSMAPeriods[index]
        
        if sender.state == .on {
            selectedSMAs.insert(period)
        } else {
            selectedSMAs.remove(period)
        }
    }
    
    @objc private func addCustomPeriod() {
        let periodText = customPeriodTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let period = Int(periodText), period > 0 else {
            showAlert(message: "Lütfen geçerli bir periyot girin (örn: 15)")
            return
        }
        
        if selectedSMAs.contains(period) {
            showAlert(message: "Bu periyot zaten seçili")
            return
        }
        
        selectedSMAs.insert(period)
        customPeriodTextField.stringValue = ""
        
        // Geçici olarak eklenen periyodu göster
        let tempLabel = NSTextField(labelWithString: "✓ SMA \(period) eklendi")
        tempLabel.font = NSFont.systemFont(ofSize: 10)
        tempLabel.textColor = NSColor.systemGreen
        tempLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tempLabel)
        
        NSLayoutConstraint.activate([
            tempLabel.topAnchor.constraint(equalTo: addCustomButton.bottomAnchor, constant: 5),
            tempLabel.leadingAnchor.constraint(equalTo: customPeriodTextField.leadingAnchor)
        ])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            tempLabel.removeFromSuperview()
        }
    }
    
    @objc private func confirmSelection() {
        delegate?.didSelectIndicators(selectedSMAs: Array(selectedSMAs).sorted())
        dismiss(nil)
    }
    
    @objc private func cancelSelection() {
        dismiss(nil)
    }
    
    private func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Uyarı"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Tamam")
        alert.runModal()
    }
}
