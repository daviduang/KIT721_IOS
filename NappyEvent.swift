//
//  NappyEvent.swift
//  KIT721 Assignment3
//
//  Created by Yi Wang on 29/4/2023.
//
import Firebase
import FirebaseFirestoreSwift

// Nappy event model
public struct NappyEvent : BaseEvent, Codable {
    @DocumentID var documentID:String?
    var title:String
    var type:String
    var note:String
    var imageURL:String?
    var date = Timestamp(date: Date())
}
