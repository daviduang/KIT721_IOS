//
//  NappyDetailViewController.swift
//  KIT721 Assignment3
//
//  Created by Yi Wang on 29/4/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class NappyDetailViewController: UIViewController {
    
    // Pass the data from history view controller
    var event: NappyEvent?
    
    // UI variables
    @IBOutlet weak var typeControl: UISegmentedControl!
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var spinnerIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start Spinner view
        spinnerIndicator.startAnimating()
        spinnerIndicator.hidesWhenStopped = true

        // Set a border to the note box
        noteTextView.layer.borderWidth = 1.0
        noteTextView.layer.borderColor = UIColor.lightGray.cgColor
        noteTextView.layer.cornerRadius = 5.0
        
        // Set the Nappy type selection
        switch event?.type {
        case "Wet":
            typeControl.selectedSegmentIndex = 0
        case "Wet Dirty":
            typeControl.selectedSegmentIndex = 1
        default:
            break
        }
        noteTextView.text = event?.note
        
        // Download and display the image
        loadImage()
    }
    
    // Load the image URL into the image view
    func loadImage() {
        guard let event = self.event, let url = URL(string: event.imageURL!) else {
            return
        }

        // Create a URLSession data task to download the image data
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error downloading image: \(error)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            // Create a UIImage from the downloaded data and update the image view on the main thread
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                self.photoImageView.image = image
                
                // Stop the spinner
                self.spinnerIndicator.stopAnimating()
            }
        }

        // Start the data task
        task.resume()
    }
    
    // Show a prompt for user to confirm the database update
    @IBAction func editButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Save Changes", message: "Are you sure you want to save changes to this event?", preferredStyle: .alert)
        
        // Update the change nappy event
        let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in
            // Ensure the event and its documentID are not nil
            if let event = self.event, let documentID = event.documentID {
                // Update the type
                switch self.typeControl.selectedSegmentIndex {
                case 0:
                    self.event?.type = "Wet"
                case 1:
                    self.event?.type = "Wet Dirty"
                default:
                    break
                }

                // Update the note
                self.event?.note = self.noteTextView.text
                
                // Update the document in Firestore
                let db = Firestore.firestore()
                do {
                    try db.collection("events").document(documentID).setData(from: self.event)
                    print("Changes saved")
                    
                    // Redirect and pass the success message to history view (From ChatGPT)
                    self.navigationController?.popViewController(animated: true)
                    if let historyVC = self.navigationController?.topViewController as? HistoryViewController {
                        historyVC.successMessage = "Event updated successfully!"
                    }
                } catch let error {
                    print("Error updating document: \(error)")
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
