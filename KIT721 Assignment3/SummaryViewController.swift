//
//  SummaryViewController.swift
//  KIT721 Assignment3
//
//  Created by Yi Wang on 1/5/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class SummaryViewController: UIViewController {
    
    // Events array to collect events
    var events: [BaseEvent] = []

    // UI labels setup
    @IBOutlet weak var sleepDurationLabel: UILabel!
    @IBOutlet weak var rightDurationLabel: UILabel!
    @IBOutlet weak var leftDurationLabel: UILabel!
    @IBOutlet weak var wetTimesLabel: UILabel!
    @IBOutlet weak var dirtyTimesLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        // Fetch events
        fetchEvents()
    }
    
    // Get the date picked by user
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        let selectedDate = sender.date
        updateSummaryData(for: selectedDate)
    }
    
    // Copy summary to click board
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        let sleepDurationText = sleepDurationLabel.text ?? ""
        let rightDurationText = rightDurationLabel.text ?? ""
        let leftDurationText = leftDurationLabel.text ?? ""
        let wetTimesText = wetTimesLabel.text ?? ""
        let dirtyTimesText = dirtyTimesLabel.text ?? ""

        let summaryText = """
        Total Left Side Feeding Duration: \(leftDurationText)
        Total Right Side Feeding Duration: \(rightDurationText)
        Total Sleep Duration: \(sleepDurationText)
        Total Wet Nappy Times: \(wetTimesText)
        Total Wet Dirty Nappy Times: \(dirtyTimesText)
        """
        
        let shareViewController = UIActivityViewController (
            activityItems: [summaryText], applicationActivities: []
        )
        
        // prevent crash on iPad
        shareViewController.popoverPresentationController?.sourceView = sender
        
        // Add a completion handler to know when the sharing is completed (From ChatGPT)
        shareViewController.completionWithItemsHandler = { (activityType, completed, items, error) in
            if completed {
                let alertController = UIAlertController(title: "Summary Shared", message: "The summary has been successfully shared.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }

        present(shareViewController, animated: true, completion: nil)
    }
    
    // Fetch events from Firestore
    func fetchEvents() {
        
        // Clear the current events array
        events.removeAll()
        
        let db = Firestore.firestore()
        let eventCollection = db.collection("events")
        
        eventCollection.getDocuments { (result, error) in
            
            // Check if server error
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            
            // Create event objects and add them into the base event list
            else {
                for document in result!.documents {
                    let data = document.data()
                    
                    if let title = data["title"] as? String {
                        switch title {
                        case "Feed Event":
                            if let feedEvent = try? document.data(as: FeedEvent.self) {
                                self.events.append(feedEvent)
                            }
                        case "Sleep Event":
                            if let sleepEvent = try? document.data(as: SleepEvent.self) {
                                self.events.append(sleepEvent)
                            }
                        case "Nappy Event":
                            if let nappyEvent = try? document.data(as: NappyEvent.self) {
                                self.events.append(nappyEvent)
                            }
                        default:
                            print("Error: Unknown event type")
                        }
                    }
                }

                // Call updateSummaryData after events have been fetched
                self.updateSummaryData(for: self.datePicker.date)
            }
        }
    }
    
    // Update the Summary
    func updateSummaryData(for date: Date) {

        // Initialize duration and time variables
        var sleepDuration: Int = 0
        var leftDuration: Int = 0
        var rightDuration: Int = 0
        var wetTimes: Int = 0
        var dirtyTimes: Int = 0
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let selectedDate = dateFormatter.string(from: date)

        // Set the varibles based on the data read from database
        for event in events {
            let eventDate = event.date.dateValue()
            if dateFormatter.string(from: eventDate) == selectedDate {
                
                // Record the duration and time into the duration and time variables
                switch event.title {
                case "Feed Event":
                    if let feedEvent = event as? FeedEvent {
                        switch feedEvent.type {
                        case "Breast Left":
                            leftDuration += feedEvent.duration
                        case "Breast Right":
                            rightDuration += feedEvent.duration
                        default:
                            break
                        }
                    }
                case "Sleep Event":
                    if let sleepEvent = event as? SleepEvent {
                        sleepDuration += sleepEvent.duration
                    }
                case "Nappy Event":
                    if let nappyEvent = event as? NappyEvent {
                        if nappyEvent.type == "Wet" {
                            wetTimes += 1
                        } else if nappyEvent.type == "Wet Dirty" {
                            dirtyTimes += 1
                        }
                    }
                default:
                    break
                }
            }
        }

        // Update UI
        sleepDurationLabel.text = formatDuration(durationInMinutes: sleepDuration)
        leftDurationLabel.text = formatDuration(durationInMinutes: leftDuration)
        rightDurationLabel.text = formatDuration(durationInMinutes: rightDuration)
        wetTimesLabel.text = "\(wetTimes) times"
        dirtyTimesLabel.text = "\(dirtyTimes) times"
    }

    // Helper function to format duration into 00:00:00 form
    func formatDuration(durationInMinutes: Int) -> String {
        let hours = durationInMinutes / 60
        let minutes = durationInMinutes % 60
        let seconds = 0

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
}
