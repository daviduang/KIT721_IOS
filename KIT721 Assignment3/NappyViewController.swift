//
//  NappyViewController.swift
//  KIT721 Assignment3
//
//  Created by Yi Wang on 29/4/2023.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseFirestoreSwift

class NappyViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // UI variables
    @IBOutlet weak var noteTextView: UITextView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var typeErrorLabel: UILabel!
    @IBOutlet weak var photoErrorLabel: UILabel!
    @IBOutlet weak var displayImageView: UIImageView!
    
    // Database storing variables
    var type = "None"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide error mesages
        typeErrorLabel.isHidden = true
        photoErrorLabel.isHidden = true

        // Set a border to the note box
        noteTextView.layer.borderWidth = 1.0
        noteTextView.layer.borderColor = UIColor.lightGray.cgColor
        noteTextView.layer.cornerRadius = 5.0
    }
    
    // Select image from Gallery by button tapped
    @IBAction func galleryTapped(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    // Display the selected image view
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            photoImageView.image = image
            dismiss(animated: true, completion: nil)
            
            // hide the initial display image view
            displayImageView.isHidden = true
        }
    }
    
    // Cancel picking image
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Save button tap action
    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        
        // Check is there is any errors
        var hasError = false
        
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
        
        // Check if an image is selected
        if photoImageView.image == nil {
            // Display error message
            photoErrorLabel.text = "Please select a photo!"
            photoErrorLabel.isHidden = false

            // Fade out the error message after 3 seconds
            photoErrorLabel.alpha = 1.0
            UIView.animate(withDuration: 3.0, animations: {
                self.photoErrorLabel.alpha = 0.0
            }, completion: { _ in
                self.photoErrorLabel.isHidden = true
            })
            hasError = true
        }
        
        // If any of the above error happened, prevent from further actions
        if (hasError) {
            return
        }
        
        // Show alert prompt for user to confirm
        let alertController = UIAlertController(title: "Save Nappy Event", message: "Do you want to create this new event?", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            let confirmAction = UIAlertAction(title: "Confirm", style: .default) { _ in
                
                // Initialise firebase firestore
                let db = Firestore.firestore()
                print("\nINITIALIZED FIRESTORE APP \(db.app.name)\n")

                // Upload the image to Firebase Storage and get the URL (From ChatGPT)
                if let image = self.photoImageView.image {
                    self.uploadImageToStorage(image) { (imageURL) in
                        if let imageURL = imageURL {
                            
                            // Add the saved document in fireBase
                            let eventCollection = db.collection("events")
                            let newEvent = NappyEvent(documentID: nil,
                                                      title: "Nappy Event",
                                                      type: self.type,
                                                      note: self.noteTextView.text,
                                                      imageURL: imageURL)
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
                                print("Error writing event to Firestore: \(error)")
                            }
                        } else {
                            // Handle error uploading image
                            print("Error uploading image")
                        }
                    }
                } else {
                    // Handle no image selected
                    print("No image selected")
                }
            }
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
    }
    
    // Upload image to Firebase Storage (From ChatGPT)
    func uploadImageToStorage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        
        // Converting the UIImage to Data using the JPEG format
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }

        // Geting a reference to the root of Firebase Storage
        let storageRef = Storage.storage().reference()
        
        // Building the storage path of image in Firebase Storage.
        let imageID = UUID().uuidString
        let imageRef = storageRef.child("images/\(imageID).jpg")

        // Uploading the image data to Firebase Storage at the generated path
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            
            // If there is an error during the upload, it prints the error, calls the completion handler with nil, and returns
            if let error = error {
                print("Error uploading image: \(error)")
                completion(nil)
                return
            }

            // If the upload is successful, it gets the download URL of the image
            imageRef.downloadURL { (url, error) in
                
                // If there is an error getting the download URL, it prints the error, calls the completion handler with nil
                if let error = error {
                    print("Error getting image download URL: \(error)")
                    completion(nil)
                    return
                }

                // It will call the completion handler with the absolute string of the URL if it successfully gets the download URL,
                // otherwise calls the completion handler with nil.
                if let url = url {
                    completion(url.absoluteString)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    /* Nappy type option module */
    @IBAction func segmentValueChanged(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        
        switch selectedIndex {
        case 0:
            type = "Wet"
        case 1:
            type = "Wet Dirty"
        default:
            break
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
