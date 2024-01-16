//
//  AlarmViewController.swift
//  KIT721 Assignment3
//
//  Created by Yi Wang on 10/5/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

// Customised feature: wake up alarm, an app nofication
class AlarmViewController: UIViewController {

    // Array to store sleep events
    var sleepEvents = [SleepEvent]()
    
    // UI variables
    @IBOutlet weak var averageSleepTime: UILabel!
    @IBOutlet weak var averageWakeUpTime: UILabel!
    @IBOutlet weak var averageSleepDuration: UILabel!
    @IBOutlet weak var timeView: UIDatePicker!
    @IBOutlet weak var alarmSwitchView: UISegmentedControl!
    
    // Configuration store
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise the time picker if have any
        if self.defaults.object(forKey: "SelectedDate") != nil {
            if let wakeUpTime = defaults.object(forKey: "SelectedDate") as? Date {
                timeView.date = wakeUpTime
            }
        }
        
        // Initialise the alarm switch view
        if self.defaults.object(forKey: "AlarmState") != nil {
            let alarmState = defaults.integer(forKey: "AlarmState")
            alarmSwitchView.selectedSegmentIndex = alarmState
        }

        // fetch events from database
        fetchEvents()
    }
    
    // When user pick a time
    @IBAction func wakeUpTimeSelected(_ sender: UIDatePicker) {
        let selectedTime = sender.date
        defaults.set(selectedTime, forKey: "SelectedDate")
        
        // Reset the alarm with the new time if alarm is currently switched on
        if alarmSwitchView.selectedSegmentIndex == 1 {
            setUpAlarm()
        }
    }
    
    // When user turn on/off the wake up alarm
    @IBAction func alarmSwitchTapped(_ sender: UISegmentedControl) {
        let alarmState = sender.selectedSegmentIndex
        defaults.set(alarmState, forKey: "AlarmState")

        // Check alarm state
        if alarmState == 1 {
            
            // When alarm is ON
            setUpAlarm()
            
            // Show set alert to user
            let alert = UIAlertController(title: "Alarm Set", message: "Your alarm has been set.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            // When alarm is OFF
            
            // Remove the notification request from the notification center
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["WakeUpAlarm"])
            
            // Show unset alert to user
            let alert = UIAlertController(title: "Alarm Unset", message: "Your alarm has been unset.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        // Update UI
        alarmSwitchView.selectedSegmentIndex = alarmState
    }
    
    // Set up alarm
    func setUpAlarm() {
        
        // Request notification permissions (From ChatGPT)
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                
                print("Notification permission granted!")
                
                // Get the selected time
                let selectedDate = self.defaults.object(forKey: "SelectedDate") as! Date
                
                // Create a calendar to extract hour and minute from the selected time
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: selectedDate)
                let minute = calendar.component(.minute, from: selectedDate)
                
                // Create a date components object with the hour and minute (From ChatGPT)
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                
                // Create a calendar trigger with the date components
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                // Create the notification content
                let content = UNMutableNotificationContent()
                content.title = "Wake Up"
                content.body = "Time to wake up your baby!!!"
                content.sound = UNNotificationSound.default
                
                // Create a notification request with the trigger
                let request = UNNotificationRequest(identifier: "WakeUpAlarm", content: content, trigger: trigger)
                
                // Add the notification request to the notification center
                UNUserNotificationCenter.current().add(request)
            } else {
                print("Notification permission denied because: \(String(describing: error))")
                
                // Display an alert to guide the user to settings
                let alert = UIAlertController(title: "Notification Permission Denied", message: "To use the alarm, please go to Settings and enable notifications for this app.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    // Fetch sleep events from Firestore
    func fetchEvents() {
        // Clear the current events array
        sleepEvents.removeAll()
        
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
                        if title == "Sleep Event" {
                            if let sleepEvent = try? document.data(as: SleepEvent.self) {
                                self.sleepEvents.append(sleepEvent)
                            }
                        }
                    }
                }
                // Call calculateAverages after events have been fetched
                self.calculateAverages()
            }
        }
    }
    
    // Calculate average sleep time, wake up time, and sleep duration
    func calculateAverages() {
        let calendar = Calendar.current

        var totalSleepTime: Double = 0
        var totalWakeUpTime: Double = 0
        var totalSleepDuration: Int = 0
        
        // Sum up the sleep time, wake up time and duration of all sleep events
        for event in sleepEvents {
            let sleepTime = event.startTime.dateValue()
            let wakeTime = event.endTime.dateValue()
            
            let sleepComponents = calendar.dateComponents([.hour, .minute, .second], from: sleepTime)
            let wakeComponents = calendar.dateComponents([.hour, .minute, .second], from: wakeTime)
            
            let sleepTimeInSeconds = sleepComponents.hour! * 3600 + sleepComponents.minute! * 60 + sleepComponents.second!
            let wakeTimeInSeconds = wakeComponents.hour! * 3600 + wakeComponents.minute! * 60 + wakeComponents.second!
            
            totalSleepTime += Double(sleepTimeInSeconds)
            totalWakeUpTime += Double(wakeTimeInSeconds)
            totalSleepDuration += event.duration
        }
        
        // Calculate the average time based on the sum
        let averageSleepTimeInSeconds = totalSleepTime / Double(sleepEvents.count)
        let averageWakeUpTimeInSeconds = totalWakeUpTime / Double(sleepEvents.count)
        let averageSleepDuration = totalSleepDuration / sleepEvents.count
        
        let averageSleepTime = formatTimeFromSeconds(totalSeconds: Int(averageSleepTimeInSeconds))
        let averageWakeUpTime = formatTimeFromSeconds(totalSeconds: Int(averageWakeUpTimeInSeconds))

        // Update UI on main thread
        DispatchQueue.main.async {
            self.averageSleepTime.text = averageSleepTime
            self.averageWakeUpTime.text = averageWakeUpTime
            self.averageSleepDuration.text = "\(averageSleepDuration)"
    
            // Set the timeView to the average wake up time if the date has not been picked before
            if self.defaults.object(forKey: "SelectedDate") == nil {
                let averageWakeUpDate = self.secondsToDate(seconds: Int(averageWakeUpTimeInSeconds))
                self.timeView.date = averageWakeUpDate
            }
        }
    }

    // Change the time format to HH:mm:ss
    func formatTimeFromSeconds(totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        let hours: Int = totalSeconds / 3600
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // Convert the time format into date picker format
    func secondsToDate(seconds: Int) -> Date {
        let hours = seconds / 3600
        let minutes = (seconds / 60) % 60
        let seconds = seconds % 60
        
        var dateComponents = DateComponents()
        dateComponents.hour = hours
        dateComponents.minute = minutes
        dateComponents.second = seconds

        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents) ?? Date()
        
        return date
    }
}
