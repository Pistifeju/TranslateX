//
//  Extensions.swift
//  TranslateMe
//
//  Created by István Juhász on 2023. 03. 14..
//

import Foundation
import UIKit

extension UIView {
    func addBasicShadow() {
        layer.shadowColor = UIColor.secondaryLabel.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 1
    }
    
    func simpleTapAnimation() {
        UIView.animate(withDuration: 0.07, animations: {
            self.alpha = 0.5
        }) { (completed) in
            UIView.animate(withDuration: 0.07) {
                self.alpha = 1.0
            }
        }
    }
}

extension UIFont {
    func withTraits(traits:UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
    }
    
    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }
    
    func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
}
