//
//  FeedViewController.swift
//  KIT721 Assignment3
//
//  Created by Yi Wang on 28/4/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class FeedViewController: UIViewController {

    // UI variables
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var startPauseButton: UIButton!
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var timerErrorLabel: UILabel!
    @IBOutlet weak var typeErrorLabel: UILabel!
    
    // Timer variables
    var timer: Timer = Timer()
    var count: Int = 0
    var isRunning: Bool = false
    
    // Database storing variables
    var startTime: Timestamp?
    var type = "None"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide error mesages
        timerErrorLabel.isHidden = true
        typeErrorLabel.isHidden = true
        
        // Set a border to the note box
        noteTextView.layer.borderWidth = 1.0
        noteTextView.layer.borderColor = UIColor.lightGray.cgColor
        noteTextView.layer.cornerRadius = 5.0
    }
    
    // Save button tap action
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        
        // Check is there is any errors
        var hasError = false
        
        // Check if startTime is available
        if startTime == nil {
            // Display error message
            timerErrorLabel.text = "Please start the timer!"
            timerErrorLabel.isHidden = false
            
            // Fade out the error message after 3 seconds (From ChatGPT)
            timerErrorLabel.alpha = 1.0
            UIView.animate(withDuration: 3.0, animations: {
                self.timerErrorLabel.alpha = 0.0
            }, completion: { _ in
                self.timerErrorLabel.isHidden = true
            })
            
            hasError = true
        }
        
        // Check if the type is selected
        if type == "None" {
            // Display error message
            typeErrorLabel.text = "Please select a type!"
            typeErrorLabel.isHidden = false
            
            // Fade out the error message after 3 seconds (From ChatGPT)
            typeErrorLabel.alpha = 1.0
            UIView.animate(withDuration: 3.0, animations: {
                self.typeErrorLabel.alpha = 0.0
            }, completion: { _ in
                self.typeErrorLabel.isHidden = true
            })
            
            hasError = true
        }
        
        // If any of the above error happened, prevent from further actions
        if (hasError) {
            return
        }
        
        // Show alert prompt for user to confirm
        let alertController = UIAlertController(title: "Save Feed Event", message: "Do you want to create this new event?", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
                
                // Initialise firebase firestore
                let db = Firestore.firestore()
                print("\nINITIALIZED FIRESTORE APP \(db.app.name)\n")
                
                // Add the saved document in fireBase
                let eventCollection = db.collection("events")
                let startTimeDate = self.startTime?.dateValue() ?? Date()
                let newEvent = FeedEvent(documentID: nil,
                                         title: "Feed Event",
                                         startTime: self.startTime ?? Timestamp(date: Date()),
                                         
                                         // Calculate the endTime based on the startTime and duration (from chartGPT)
                                         endTime: Timestamp(date: startTimeDate.addingTimeInterval(TimeInterval(self.count))),
                                         duration: self.count,
                                         type: self.type,
                                         note: self.noteTextView.text)
                do {
                    try eventCollection.addDocument(from: newEvent, completion: { (err) in
                        if let err = err {
                            print("Error adding document: \(err)")
                        } else {
                            print("Successfully created event")
                            
                            // Show success alert with an OK button
                            let successAlertController = UIAlertController(title: "Success", message: "Event created successfully!", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                                
                                // Redirect back to the home page
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                            successAlertController.addAction(okAction)
                            self.present(successAlertController, animated: true, completion: nil)
                            
                        }
                    })
                } catch let error {
                    print("Error writing city to Firestore: \(error)")
                }
            }
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
    }
    
    /* Timer module implementation */
    //update the start and pause button when it is tapped
    @IBAction func startPauseTapped(_ sender: UIButton) {
        
        // Update the timer state
        isRunning = !isRunning
        if (isRunning) {
            
            // Record the start time
            startTime = Timestamp(date: Date())
            
            startPauseButton.setTitle("Pause", for: .normal)
            startPauseButton.setTitleColor(UIColor.red, for: .normal)
            startPauseButton.setImage(UIImage(systemName: "pause"), for: .normal)
            startPauseButton.tintColor = UIColor.red
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
        } else {
            startPauseButton.setTitle("Start", for: .normal)
            startPauseButton.setTitleColor(UIColor.systemBlue, for: .normal)
            startPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
            startPauseButton.tintColor = UIColor.systemBlue
            timer.invalidate()
        }
    }
    
    // Update both the timer counter and the timer label
    @objc func timerCounter() {
        count = count + 1
        timerLabel.text = secondsToTimerLabel(secondCount: count)
    }
    
    // Convert seconds to timer label view (From ChatGPT)
    func secondsToTimerLabel(secondCount: Int) -> String {
        let hours = secondCount / 3600
        let minutes = (secondCount % 3600) / 60
        let seconds = (secondCount % 3600) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // Reset timer
    @IBAction func resetTapped(_ sender: UIButton) {
        timer.invalidate()
        count = 0
        timerLabel.text = "00:00:00"
        isRunning = false
        startTime = nil
        startPauseButton.setTitle("Start", for: .normal)
        startPauseButton.setTitleColor(UIColor.systemBlue, for: .normal)
        startPauseButton.setImage(UIImage(systemName: "play"), for: .normal)
        startPauseButton.tintColor = UIColor.systemBlue
    }
    
    // Feeding type option module
    @IBAction func segmentValueChanged(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        
        switch selectedIndex {
        case 0:
            type = "Breast Left"
        case 1:
            type = "Breast Right"
        case 2:
            type = "Bottle"
        default:
            break
        }
    }
}
