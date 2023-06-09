//
//  TXPermission.swift
//  TranslateX
//
//  Created by István Juhász on 2023. 03. 19..
//

import Foundation
import Speech
import UIKit
import PhotosUI

final class TXPermission {
    static let shared = TXPermission()
    
    private init() {}
    
    public func checkCameraPermission(completion: @escaping(Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self] authStatus in
            guard self != nil else { return }
            DispatchQueue.main.async {
                switch authStatus {
                case true:
                    completion(true)
                case false:
                    completion(false)
                }
            }
        }
    }

    public func checkPhotoLibraryPermission(completion: @escaping(Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] authStatus in
            guard self != nil else { return }
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    completion(true)
                case .limited:
                    completion(true)
                case .restricted:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }
    }
    
    public func checkSpeechPermissions(completion: @escaping(Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            guard self != nil else { return }
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }
    }
    
    public func handlePermissionFailed(title: String, message: String) -> UIAlertController {
        let ac = UIAlertController(title: title,
                                   message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Open settings", style: .default) { _ in
            let url = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(url)
        })
        ac.addAction(UIAlertAction(title: "Close", style: .cancel))
        return ac
    }
}
