//
//  FeedEvent.swift
//  KIT721 Assignment3
//
//  Created by Yi Wang on 29/4/2023.
//
import Firebase
import FirebaseFirestoreSwift

// Feed event model
public struct FeedEvent : BaseEvent, Codable {
    @DocumentID var documentID:String?
    var title:String
    var startTime:Timestamp
    var endTime:Timestamp
    var duration:Int
    var type:String
    var note:String
    var date = Timestamp(date: Date())
}
