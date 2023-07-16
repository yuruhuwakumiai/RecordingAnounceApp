//
//  RecordingModel.swift
//  RecordingAnounceApp
//
//  Created by 橋元雄太郎 on 2023/07/16.
//

import SwiftUI
import RealmSwift
import Combine
import AVFoundation

// MARK: - Model
class Recording: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var fileURL: String = ""
    @objc dynamic var createdAt = Date()
    @objc dynamic var isPlaying: Bool = false
    @objc dynamic var name: String = ""

    override static func primaryKey() -> String? {
        return "id"
    }
}

// MARK: - ViewModel
class RecorderViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var realm: Realm
//    @Published var recordings: Results<Recording>
    @Published var recordings: Results<Recording> // change this line
    @Published var playingRecordingID: String? // add this new property

    @Published var recording = false
    @Published var repeatMode = false
    @Published var showAlert = false
    @Published var showSheet = false

    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var currentRecordingID: String?

    override init() {
        realm = try! Realm()
        recordings = realm.objects(Recording.self).sorted(byKeyPath: "createdAt", ascending: false)
        super.init()
    }

    func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            print("Failed to set up recording session: \(error)")
        }

        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileName = documentPath.appendingPathComponent("\(Date().toString(dateFormat: "dd-MM-YY_'at'_HH:mm:ss")).m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName, settings: settings)
            audioRecorder.record()

            recording = true
        } catch {
            print("Could not start recording: \(error)")
        }
    }


    func stopRecording() {
        audioRecorder.stop()
        recording = false
        showSheet = true

        // Use the entire URL, not just the last path component
        let audioFileName = audioRecorder.url.absoluteString
        let recording = Recording()
        recording.fileURL = audioFileName // This line is modified
        recording.createdAt = Date()
        recording.name = "New Recording"

        do {
            try realm.write {
                realm.add(recording)
            }
        } catch {
            print("Failed to save recording: \(error)")
        }

        currentRecordingID = recording.id
    }




    func getRecording(by id: String) -> Recording? {
        return realm.object(ofType: Recording.self, forPrimaryKey: id)
    }

    func playRecording(id: String) {
        if let recording = getRecording(by: id) {
            do {
                // Use the entire URL, not just the filename
                let audioFileUrl = URL(string: recording.fileURL)!

                print("Trying to play audio file at: \(audioFileUrl)")

                audioPlayer = try AVAudioPlayer(contentsOf: audioFileUrl)
                audioPlayer.delegate = self
                audioPlayer.numberOfLoops = repeatMode ? -1 : 0
                audioPlayer.play()

                try realm.write {
                    recording.isPlaying = true
                }

                playingRecordingID = id
            } catch {
                print("Could not play recording: \(error)")
            }
        }
    }








    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let recording = realm.objects(Recording.self).filter("fileURL == %@", player.url!.absoluteString).first {
            do {
                try realm.write {
                    recording.isPlaying = false
                }

                playingRecordingID = nil // add this line
            } catch {
                print("Failed to update isPlaying status: \(error)")
            }
        }
    }

    func stopPlaying(id: String) {
        if let recording = getRecording(by: id) {
            audioPlayer.stop()

            do {
                try realm.write {
                    recording.isPlaying = false
                }

                playingRecordingID = nil // add this line
            } catch {
                print("Failed to update isPlaying status: \(error)")
            }
        }
    }

    func deleteRecording(id: String) {
        if let recording = realm.object(ofType: Recording.self, forPrimaryKey: id) {
            do {
                try realm.write {
                    realm.delete(recording)
                }
            } catch {
                print("Failed to delete recording: \(error)")
            }
        }
    }

    func deleteRecordingAndUpdateList(id: String) {
        if let recording = realm.object(ofType: Recording.self, forPrimaryKey: id) {
            do {
                try realm.write {
                    realm.delete(recording)
                    self.recordings = self.realm.objects(Recording.self).sorted(byKeyPath: "createdAt", ascending: false)
                }
            } catch {
                print("Failed to delete recording: \(error)")
            }
        }
    }
}

extension Date {
    func toString(dateFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
