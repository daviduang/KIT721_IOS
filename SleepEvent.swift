//
//  SleepEvent.swift
//  KIT721 Assignment3
//
//  Created by Yi Wang on 29/4/2023.
//
import Firebase
import FirebaseFirestoreSwift

// Sleep event model
public struct SleepEvent : BaseEvent, Codable {
    @DocumentID var documentID:String?
    var title:String
    var startTime:Timestamp
    var endTime:Timestamp
    var duration:Int
    var note:String
    var date = Timestamp(date: Date())
}
