//
//  MainLanguageNameLabelView.swift
//  TranslateMe
//
//  Created by István Juhász on 2023. 03. 14..
//

import Foundation

import UIKit

class MainLanguageNameLabelView: UIView {
    
    // MARK: - Properties
    
    private let languageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "English"
        label.textColor = .systemBlue
        label.font = UIFont.preferredFont(forTextStyle: .headline).bold()
        return label
    }()
    
    private let downArrowImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.down")?.withTintColor(UIColor.secondarySystemBackground))
        imageView.tintColor = UIColor.systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        let width = languageLabel.bounds.width + downArrowImageView.bounds.width + 8 //Added +8 because of the trailingAnchor multiplier 1.
        let height = languageLabel.bounds.height
        return CGSize(width: width, height: height)
    }
    
    // MARK: - Helpers
    
    private func configureUI() {
        addSubview(languageLabel)
        addSubview(downArrowImageView)
        
        backgroundColor = .systemBackground
        NSLayoutConstraint.activate([
            languageLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            languageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            downArrowImageView.leadingAnchor.constraint(equalToSystemSpacingAfter: languageLabel.trailingAnchor, multiplier: 1),
            downArrowImageView.centerYAnchor.constraint(equalTo: languageLabel.centerYAnchor),
        ])
    }
    
    public func configure(withLanguage text: String) {
        self.languageLabel.text = text
    }
    
    // MARK: - Selectors
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        simpleTapAnimation()
    }
}
