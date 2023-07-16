//
//  RealmModel.swift
//  RecordingAnounceApp
//
//  Created by 橋元雄太郎 on 2023/07/16.
//
import SwiftUI
import RealmSwift

class RecordingObject: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var fileURL: String = ""
    @objc dynamic var createdAt: Date = Date()
    @objc dynamic var isPlaying: Bool = false
    @objc dynamic var name: String = ""
}

