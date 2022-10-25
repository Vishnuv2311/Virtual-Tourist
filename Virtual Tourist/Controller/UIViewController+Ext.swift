//
//  UIViewController+Ext.swift
//  Virtual Tourist
//
//  Created by Vishnu V on 22/10/22.
//

import UIKit

extension UIViewController {

    func showOKAlert(error:LocalizedError? = nil) {
        let title = error?.localizedDescription ?? "Unknown Error"
        showOKAlert(title: title)
    }
    
    func showOKAlert(title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}
