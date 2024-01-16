//
//  HistoryViewController.swift
//  KIT721 Assignment3
//
//  Created by Yi Wang on 30/4/2023.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // List for storing history items with all event types
    var histories = [BaseEvent]()

    // History table view variable
    @IBOutlet weak var tableView: UITableView!
    
    // Success message passed in
    var successMessage: String?
    
    // Store and set filter option
    var currentFilter: String?
    @IBOutlet weak var listOptions: UISegmentedControl!
    
    // Store the sorting option (From ChatGPT)
    enum SortingOrder {
        case chronological
        case reverseChronological
    }
    var currentSortingOrder: SortingOrder = .chronological
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise the table view
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Call fetchEvents to populate histories
        fetchEvents(eventFilter: currentFilter)
        
        // Fetch the databse only when the user is visiting the history page,
        // Ensure the list is always up to date (From ChatGPT)
        if let message = successMessage {
            showSuccessPrompt(message: message)
            
            // Reset the success message after displaying it
            successMessage = nil
        }
        
        // Set the selected index of the segmented control based on the current filter
        if let filter = currentFilter {
            switch filter {
            case "Feed Event":
                listOptions.selectedSegmentIndex = 1
            case "Sleep Event":
                listOptions.selectedSegmentIndex = 2
            case "Nappy Event":
                listOptions.selectedSegmentIndex = 3
            default:
                listOptions.selectedSegmentIndex = 0
            }
        } else {
            listOptions.selectedSegmentIndex = 0
        }
    }
    
    // Handle the list option value changed event
    @IBAction func listOptionValueChanged(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        
        switch selectedIndex {
        case 1:
            fetchEvents(eventFilter: "Feed Event")
        case 2:
            fetchEvents(eventFilter: "Sleep Event")
        case 3:
            fetchEvents(eventFilter: "Nappy Event")
        default:
            fetchEvents()
        }
    }
    
    // Handle history list sorting view options
    @IBAction func menuTapped(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: nil, message: "Choose a sorting option", preferredStyle: .actionSheet)

        let chronologicalOrderAction = UIAlertAction(title: "In Chronological Order", style: .default) { _ in
            self.currentSortingOrder = .chronological
            self.fetchEvents(eventFilter: self.currentFilter)
        }
        alertController.addAction(chronologicalOrderAction)

        let reverseChronologicalOrderAction = UIAlertAction(title: "In Reverse Chronological Order", style: .default) { _ in
            self.currentSortingOrder = .reverseChronological
            self.fetchEvents(eventFilter: self.currentFilter)
        }
        alertController.addAction(reverseChronologicalOrderAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return histories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryTableViewCell", for: indexPath)

        //get the history for this row
        let history = histories[indexPath.row]

        //down-cast the cell from UITableViewCell to our cell class HistoryTableViewCell
        //note, this could fail, so we use an if let.
        if let historyCell = cell as? HistoryTableViewCell
        {
            //populate the cell
            historyCell.titleLabel.text = history.title
            
            // Format the date from the Timestamp object
            let date = history.date.dateValue()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            historyCell.dateLabel.text = dateFormatter.string(from: date)
            
        }

        return cell
    }
    
    // When user taped a row, navigate the user to the corresponding detail view
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect the cell to remove the selection highlight
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Get the selected event from histories array
        let selectedEvent = histories[indexPath.row]

        // Check the title and navigate to the appropriate view controller
        switch selectedEvent.title {
        case "Feed Event":
            let feedEventDetailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FeedEventDetail") as! FeedDetailViewController
            if let feedEvent = selectedEvent as? FeedEvent {
                feedEventDetailVC.event = feedEvent
            }
            self.navigationController?.pushViewController(feedEventDetailVC, animated: true)

        case "Sleep Event":
            let sleepEventDetailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SleepEventDetail") as! SleepDetailViewController
            if let sleepEvent = selectedEvent as? SleepEvent {
                sleepEventDetailVC.event = sleepEvent
            }
            self.navigationController?.pushViewController(sleepEventDetailVC, animated: true)

        case "Nappy Event":
            let nappyEventDetailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChangeNappyEventDetail") as! NappyDetailViewController
            if let nappyEvent = selectedEvent as? NappyEvent {
                nappyEventDetailVC.event = nappyEvent
            }
            self.navigationController?.pushViewController(nappyEventDetailVC, animated: true)

        default:
            print("Error: Unknown event type")
        }
    }
    
    // Fetch history events
    func fetchEvents(eventFilter: String? = nil) {
        // Clear the current histories array
        histories.removeAll()

        // Initialise firebase firestore
        let db = Firestore.firestore()
        print("\nINITIALIZED FIRESTORE APP \(db.app.name)\n")

        // Retrieve the saved document from fireBase
        let eventCollection = db.collection("events")
        eventCollection.getDocuments() { (result, err) in
            
            //check for server error
            if let err = err
            {
                print("Error getting documents: \(err)")
            }
            else
            {
                // Store the current filter option (From ChatGPT)
                self.currentFilter = eventFilter
                
                //loop through the results
                for document in result!.documents {
                    let data = document.data()
                    
                    // Filter for handling the options
                    if let title = data["title"] as? String {
                        // If a filter is provided and the title doesn't match, skip filtering
                        if let filter = eventFilter, filter != title {
                            continue
                        }
                        
                        // Store the events into the history list
                        switch title {
                        case "Feed Event":
                            do {
                                let feedEvent = try document.data(as: FeedEvent.self)
                                self.histories.append(feedEvent)
                            } catch let error {
                                print("Error decoding FeedEvent: \(error)")
                            }
                        case "Sleep Event":
                            do {
                                let sleepEvent = try document.data(as: SleepEvent.self)
                                self.histories.append(sleepEvent)
                            } catch let error {
                                print("Error decoding SleepEvent: \(error)")
                            }
                        case "Nappy Event":
                            do {
                                let nappyEvent = try document.data(as: NappyEvent.self)
                                self.histories.append(nappyEvent)
                            } catch let error {
                                print("Error decoding NappyEvent: \(error)")
                            }
                        default:
                            print("Error: Unknown event type")
                        }
                    } else {
                        print("Error: Document doesn't have a title")
                    }
                }

                // Reload the table view with the new data with sorting options (From ChatGPT)
                DispatchQueue.main.async {
                    // Apply the sorting order
                    switch self.currentSortingOrder {
                    case .chronological:
                        self.histories.sort { $0.date.dateValue() < $1.date.dateValue() }
                    case .reverseChronological:
                        self.histories.sort { $0.date.dateValue() > $1.date.dateValue() }
                    }
                    
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // Show success message prompt for delete, edit actions
    public func showSuccessPrompt(message: String) {
        let alertController = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        
        present(alertController, animated: true, completion: nil)
        
        // Dismiss the alert after 2 seconds and pop the current view controller to return to the history view controller
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            alertController.dismiss(animated: true) {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

}
