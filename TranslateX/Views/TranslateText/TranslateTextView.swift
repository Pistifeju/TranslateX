//
//  TranslateTextView.swift
//  TranslateX
//
//  Created by István Juhász on 2023. 03. 14..
//

import Foundation
import UIKit
import MLKitTranslate
import JGProgressHUD

protocol TranslateTextViewDelegate: AnyObject {
    func showPickerViewAlert(pickerView: UIPickerView, alert: UIAlertController)
    func handleSpeechPermissionFailed(ac: UIAlertController)
    func handleShowErrorAlert(title: String, message: String)
    func handleShowIdentifiedLanguageNotDownloadedAlert(completion: @escaping(Bool) -> Void)
}

final class TranslateTextView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: TranslateTextViewDelegate?
    
    private var viewModel = TranslateTextViewViewModel()
    
    private lazy var sourceTranslateTextTextView = TranslateTextTextView(translateOrderLabel: "Translate from")
    private lazy var targetTranslateTextTextView = TranslateTextTextView(translateOrderLabel: "Translate to", allowEditingTextView: false)
    private let translateBetweenTwoLanguageSelectorView = TranslateBetweenTwoLanguageSelectorView()
    
    private let languagePickerView: UIPickerView = {
        let pickerView = UIPickerView(frame: .zero)
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        return pickerView
    }()
    
    // MARK: - Lifecycle
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        NotificationCenter.default.addObserver(self, selector: #selector(transcriptionChanged), name: Notification.Name(viewModel.speechNotificationName), object: nil)
        setupViewsDelegatesAndDataSource()
        configureViews()
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Helpers
    
    private func setupViewsDelegatesAndDataSource() {
        translateBetweenTwoLanguageSelectorView.delegate = self
        languagePickerView.delegate = self
        languagePickerView.dataSource = self
        sourceTranslateTextTextView.delegate = self
        targetTranslateTextTextView.delegate = self
    }

    private func configureUI() {
        backgroundColor = .systemBackground
        addSubview(translateBetweenTwoLanguageSelectorView)
        addSubview(sourceTranslateTextTextView)
        addSubview(targetTranslateTextTextView)
        
        NSLayoutConstraint.activate([
            translateBetweenTwoLanguageSelectorView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 2),
            translateBetweenTwoLanguageSelectorView.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 2),
            trailingAnchor.constraint(equalToSystemSpacingAfter: translateBetweenTwoLanguageSelectorView.trailingAnchor, multiplier: 2),
            
            sourceTranslateTextTextView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 2),
            sourceTranslateTextTextView.topAnchor.constraint(equalToSystemSpacingBelow: translateBetweenTwoLanguageSelectorView.bottomAnchor, multiplier: 2),
            trailingAnchor.constraint(equalToSystemSpacingAfter: sourceTranslateTextTextView.trailingAnchor, multiplier: 2),
            
            targetTranslateTextTextView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 2),
            targetTranslateTextTextView.topAnchor.constraint(equalToSystemSpacingBelow: sourceTranslateTextTextView.bottomAnchor, multiplier: 2),
            trailingAnchor.constraint(equalToSystemSpacingAfter: targetTranslateTextTextView.trailingAnchor, multiplier: 2),
        ])
    }
    
    private func configureViews(speakButtonIsSelected: Bool = false) {
        let languagePair = viewModel.languagePair
        self.translateBetweenTwoLanguageSelectorView.configure(sourceLanguageString: languagePair.sourceLanguageString, targetLanguageString: languagePair.targetLanguageString)
        self.sourceTranslateTextTextView.configure(languageString: languagePair.sourceLanguageString, textViewString: languagePair.sourceText, speakButtonIsSelected: speakButtonIsSelected)
        self.targetTranslateTextTextView.configure(languageString: languagePair.targetLanguageString, textViewString: languagePair.targetText, speakButtonIsSelected: speakButtonIsSelected)
    }
    
    // MARK: - Selectors
    
    @objc private func transcriptionChanged() {
        viewModel.languagePair.sourceText = viewModel.speechRecognizer.transcription ?? ""
        viewModel.languagePair.translate(from: viewModel.languagePair.sourceLanguage, to: viewModel.languagePair.targetLanguage, translateFromTarget: false) { [weak self] in
            self?.configureViews(speakButtonIsSelected: true)
        }
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource

extension TranslateTextView: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return TXLanguageModels.shared.localModels.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return TXLanguages.shared.createLanguageStringWithTranslateLanguage(from: TXLanguageModels.shared.localModels[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return UIScreen.main.bounds.height / 10
    }
}

// MARK: - TranslateBetweenTwoLanguageSelectorViewDelegate

extension TranslateTextView: TranslateBetweenTwoLanguageSelectorViewDelegate {
    func didPressSwitchLanguagesButton() {
        viewModel.languagePair.switchLanguages()
        self.configureViews()
        viewModel.stopSpeechRecognizerListening()
    }
    
    func didPressSelectLanguage(languageLabel: MainLanguageNameLabelView) {
        languagePickerView.reloadAllComponents()
        
        let alert = UIAlertController(title: "Downloaded Languages", message: "", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Select", style: .default, handler: { [weak self] _ in
            guard let strongSelf = self else { return }
            
            let selectedIndex = strongSelf.languagePickerView.selectedRow(inComponent: 0)
            let selectedLanguage = TXLanguageModels.shared.localModels[selectedIndex]
            let selectedLanguageString = TXLanguages.shared.createLanguageStringWithTranslateLanguage(from: selectedLanguage)
            
            languageLabel.configure(withLanguage: selectedLanguageString)
            
            if languageLabel.source {
                strongSelf.viewModel.languagePair.sourceLanguage = selectedLanguage
            } else {
                strongSelf.viewModel.languagePair.targetLanguage = selectedLanguage
            }
            
            let languagePair = strongSelf.viewModel.languagePair
            languagePair.translate(from: languagePair.targetLanguage, to: languagePair.sourceLanguage, translateFromTarget: false) {
                strongSelf.configureViews()
            }
        }))
        
        delegate?.showPickerViewAlert(pickerView: languagePickerView, alert: alert)
    }

}

// MARK: - TranslateTextViewDelegate

extension TranslateTextView: TranslateTextTextViewDelegate {
    func didTapIdentifiedLanguage(languageCode code: String) {
        let language = TXLanguages.shared.createTranslateLanguageWithLanguageCode(from: code)
        guard let language = language else { return }
        if TXLanguageModels.shared.checkIfLanguageInDownloadedLanguages(language: language) {
            viewModel.languagePair.sourceLanguage = language
            let languagePair = viewModel.languagePair
            languagePair.translate(from: languagePair.targetLanguage, to: languagePair.sourceLanguage, translateFromTarget: false) { [weak self] in
                self?.configureViews()
                self?.sourceTranslateTextTextView.hideIdentifiedLanguageLabel()
            }
        } else {
            delegate?.handleShowIdentifiedLanguageNotDownloadedAlert(completion: { didPressDownload in
                switch didPressDownload {
                case true:
                    let languagePair = self.viewModel.languagePair
                    languagePair.sourceLanguage = language
                    let progressHud = self.viewModel.createDownloadLanguageProgressHud()
                    progressHud.show(in: self, animated: true)
                    TXLanguageModels.shared.downloadLanguageIfNeeded(sourceLanguage: languagePair.sourceLanguage, targetLanguage: languagePair.targetLanguage) { [weak self] error in
                        guard let strongSelf = self else { return }
                        progressHud.dismiss(animated: true)
                        if let error = error {
                            strongSelf.delegate?.handleShowErrorAlert(title: "Error", message: error.localizedDescription)
                            return
                        }
                        
                        let languagePair = strongSelf.viewModel.languagePair
                        languagePair.translate(from: languagePair.targetLanguage, to: languagePair.sourceLanguage, translateFromTarget: false) {
                            strongSelf.configureViews()
                            strongSelf.sourceTranslateTextTextView.hideIdentifiedLanguageLabel()
                        }
                    }
                case false:
                    break
                }
            })
        }
    }
    
    func didTapSpeakButton(textView: UITextView, recording: Bool, ac: UIAlertController?) {
        if let ac = ac {
            delegate?.handleSpeechPermissionFailed(ac: ac)
        }
        
        if recording {
            do {
                try viewModel.speechRecognizer.startListening(language: viewModel.languagePair.sourceLanguage, notificationName: viewModel.speechNotificationName)
            } catch {
                delegate?.handleShowErrorAlert(title: "Error", message: "There was an error starting speech recognition.")
            }
        } else {
            viewModel.stopSpeechRecognizerListening()
        }
    }
    
    func didTapVoiceButton(sourceTextViewString: String, sourceTextView: Bool) {
        let language = sourceTextView ? viewModel.languagePair.sourceLanguage : viewModel.languagePair.targetLanguage
        TXSpeaker.shared.speak(text: sourceTextViewString, language: language)
    }
    
    func textViewDidChange(sourceTextViewString: String) {
        TXLanguageIdentifier.shared.identifyLanguage(for: sourceTextViewString) { [weak self] languageCode, error in
            if let languageCode {
                self?.sourceTranslateTextTextView.showIdentifiedLanguageLabel(with: languageCode)
            } else {
                self?.sourceTranslateTextTextView.hideIdentifiedLanguageLabel()
            }
        }
        
        viewModel.languagePair.sourceText = sourceTextViewString
        let languagePair = viewModel.languagePair
        languagePair.translate(from: languagePair.sourceLanguage, to: languagePair.targetLanguage, translateFromTarget: false) { [weak self] in
            self?.targetTranslateTextTextView.configure(languageString: languagePair.targetLanguageString, textViewString: languagePair.targetText, speakButtonIsSelected: false)
        }
    }
}
