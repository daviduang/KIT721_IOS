//
//  FeedDetailViewController.swift
//  KIT721 Assignment3
//
//  Created by Yi Wang on 29/4/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class FeedDetailViewController: UIViewController {
    
    // Pass the data from history view controller
    var event: FeedEvent?

    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var typeControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set a border to the note box
        noteTextView.layer.borderWidth = 1.0
        noteTextView.layer.borderColor = UIColor.lightGray.cgColor
        noteTextView.layer.cornerRadius = 5.0
        
        // Set data passed from the history view controller (From ChatGPT)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let startTime = event?.startTime.dateValue() {
            startTimeLabel.text = dateFormatter.string(from: startTime)
        }
        
        if let endTime = event?.endTime.dateValue() {
            endTimeLabel.text = dateFormatter.string(from: endTime)
        }
        
        if let duration = event?.duration {
            durationLabel.text = "\(duration)"
        }
        
        // Set the feeding type selection
        switch event?.type {
        case "Breast Left":
            typeControl.selectedSegmentIndex = 0
        case "Breast Right":
            typeControl.selectedSegmentIndex = 1
        case "Bottle":
            typeControl.selectedSegmentIndex = 2
        default:
            break
        }
        
        noteTextView.text = event?.note
    }
    
    // Show a prompt for user to confirm the database update
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Save Changes", message: "Are you sure you want to save changes to this event?", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in
 
            // Update the changes to database
            if let event = self.event, let documentID = event.documentID {
                let db = Firestore.firestore()
                
                // Update note and type fields
                let note = self.noteTextView.text ?? ""
                let type: String
                
                // Convert the segment index into feed type string
                switch self.typeControl.selectedSegmentIndex {
                case 0:
                    type = "Breast Left"
                case 1:
                    type = "Breast Right"
                case 2:
                    type = "Bottle"
                default:
                    type = ""
                }
                
                db.collection("events").document(documentID).updateData([
                    "note": note,
                    "type": type
                ]) { error in
                    if let error = error {
                        print("Error updating document: \(error)")
                    } else {
                        print("Document successfully updated!")
                        
                        // Redirect and pass the success message to history view (From ChatGPT)
                        self.navigationController?.popViewController(animated: true)
                        if let historyVC = self.navigationController?.topViewController as? HistoryViewController {
                            historyVC.successMessage = "Event updated successfully!"
                        }
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Show a confirmation prompt when delete button tapped
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Delete Alert", message: "Are you sure you want to delete this event?", preferredStyle: .alert)
        
        // If user confirm the deletion
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            
            // Ensure the event and its documentID are not nil
            if let event = self.event, let documentID = event.documentID {
                
                // Delete the document from Firestore
                let db = Firestore.firestore()
                db.collection("events").document(documentID).delete() { error in
                    if let error = error {
                        print("Error removing document: \(error)")
                    } else {
                        // Show delete success message
                        print("Document successfully removed!")
                        
                        // Redirect and pass the success message to history view (From ChatGPT)
                        self.navigationController?.popViewController(animated: true)
                        if let historyVC = self.navigationController?.topViewController as? HistoryViewController {
                            historyVC.successMessage = "Event deleted successfully!"
                        }
                    }
                }
            }
        }
        
        // If user cancel the deletion
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

}
