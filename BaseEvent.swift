//
//  BaseEvent.swift
//  KIT721 Assignment3
//
//  Created by Yi Wang on 29/4/2023.
//

import Firebase
import FirebaseFirestoreSwift

// Base event model
protocol BaseEvent: Codable {
    var documentID: String? { get }
    var title: String { get }
    var date: Timestamp { get }
}
