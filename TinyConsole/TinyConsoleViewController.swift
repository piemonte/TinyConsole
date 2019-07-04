//
//  TinyConsoleViewController.swift
//  TinyConsole
//
//  Created by Devran Uenal on 28.11.16.
//
//

import UIKit
import MessageUI

class TinyConsoleViewController: UIViewController {
    let consoleTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = UIColor.black
        textView.isEditable = false
        return textView
    }()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        TinyConsole.shared.textView = consoleTextView
        view.addSubview(consoleTextView)
        
        TinyConsole.shared.tinyConsoleController = self.parent as? TinyConsoleController
    
        let addMarkerGesture = UISwipeGestureRecognizer(target: self, action: #selector(addMarker))
        view.addGestureRecognizer(addMarkerGesture)
        
        let addCustomTextGesture = UITapGestureRecognizer(target: self, action: #selector(customText))
        addCustomTextGesture.numberOfTouchesRequired = 2
        if #available(iOS 9, *) {
            view.addGestureRecognizer(addCustomTextGesture)
        } else {
            consoleTextView.addGestureRecognizer(addCustomTextGesture)
        }
        
        let showAdditionalActionsGesture = UITapGestureRecognizer(target: self, action: #selector(additionalActions))
        showAdditionalActionsGesture.numberOfTouchesRequired = 3
        view.addGestureRecognizer(showAdditionalActionsGesture)
        
        setupConstraints()
    }
    
    func setupConstraints() {
        consoleTextView.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 9, *) {
            consoleTextView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            consoleTextView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            consoleTextView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            consoleTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        } else {
            NSLayoutConstraint(item: consoleTextView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: consoleTextView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: consoleTextView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0).isActive = true
            NSLayoutConstraint(item: consoleTextView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        }
    }
    
    @objc func customText(sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Custom Log", message: "Enter text you want to log.", preferredStyle: UIAlertController.Style.alert)
        alert.addTextField { (textField: UITextField) in
            textField.keyboardType = .alphabet
        }
        
        let okAction = UIAlertAction(title: "Add log", style: UIAlertAction.Style.default) {
            (action: UIAlertAction) in
            if let text = alert.textFields?.first?.text, !text.isEmpty {
                TinyConsole.print(text)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func additionalActions(sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        let sendAction = UIAlertAction(title: "Send…", style: UIAlertAction.Style.default) {
            (action: UIAlertAction) in
            DispatchQueue.main.async {
                if let text = TinyConsole.shared.textView?.text {
                    if MFMailComposeViewController.canSendMail() {
                        let composeViewController = MFMailComposeViewController(nibName: nil, bundle: nil)
                        composeViewController.mailComposeDelegate = self
                        composeViewController.setSubject("Console Log")
                        composeViewController.setMessageBody(text, isHTML: false)
                        self.present(composeViewController, animated: true, completion: nil)
                    } else {
                        let activityItems: [Any] = [text]
                        
                        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                        activityViewController.excludedActivityTypes = [.saveToCameraRoll,
                                                                        .print,
                                                                        .assignToContact,
                                                                        .addToReadingList,
                                                                        .postToVimeo,
                                                                        .postToWeibo,
                                                                        .postToFlickr]
                        activityViewController.completionWithItemsHandler = { (activityType, completed, items, error) in
                            if let _ = error {
                                self.dismiss(animated: false, completion: {
                                })
                            } else if completed {
                                // prepare message
                                var confirmMessage: String? = nil
                                if let activity = activityType {
                                    switch activity {
                                    case UIActivity.ActivityType.copyToPasteboard:
                                        confirmMessage = NSLocalizedString("Copied!", comment: "Copied!")
                                        break
                                    case UIActivity.ActivityType.postToFacebook:
                                        fallthrough
                                    case UIActivity.ActivityType.postToTwitter:
                                        fallthrough
                                    case UIActivity.ActivityType.postToWeibo:
                                        fallthrough
                                    case UIActivity.ActivityType.postToTencentWeibo:
                                        confirmMessage = NSLocalizedString("Posted!", comment: "Posted!")
                                        break
                                    case UIActivity.ActivityType.postToFlickr:
                                        fallthrough
                                    case UIActivity.ActivityType.postToVimeo:
                                        confirmMessage = NSLocalizedString("Posted!", comment: "Posted!")
                                        break
                                    case UIActivity.ActivityType.airDrop:
                                        fallthrough
                                    case UIActivity.ActivityType.mail:
                                        fallthrough
                                    case UIActivity.ActivityType.message:
                                        fallthrough
                                    default:
                                        confirmMessage = NSLocalizedString("Sent!", comment: "Sent!")
                                        break
                                    }
                                }
                                
                                if let confirmMessage = confirmMessage {
                                    let confirmAlert = UIAlertController(title: confirmMessage,
                                                                         message: nil,
                                                                         preferredStyle: .alert)
                                    self.present(confirmAlert, animated: true, completion:nil)
                                }
                            }
                        }
                        self.present(activityViewController, animated: true)
                    }
                }
            }
        }
        
        let clearAction = UIAlertAction(title: "Clear", style: UIAlertAction.Style.destructive) {
            (action: UIAlertAction) in
            TinyConsole.clear()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
        
        alert.addAction(sendAction)
        alert.addAction(clearAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func addMarker(sender: UISwipeGestureRecognizer) {
        TinyConsole.addMarker()
    }
}

extension TinyConsoleViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
