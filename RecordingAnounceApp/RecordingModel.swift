//
//  RecordingModel.swift
//  RecordingAnounceApp
//
//  Created by 橋元雄太郎 on 2023/07/16.
//
import SwiftUI
import Combine
import AVFoundation

// MARK: - Model
struct Recording: Identifiable {
    let id = UUID()
    let fileURL: URL
    let createdAt: Date
    var isPlaying: Bool = false
    var name: String
}

// MARK: - ViewModel
class RecorderViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var recordings = [Recording]()
    @Published var recording = false
    @Published var repeatMode = false
    @Published var showAlert = false
    @Published var showSheet = false

    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var currentRecordingID: UUID?

    func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            print("Failed to set up recording session")
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
            print("Could not start recording")
        }
    }

    func stopRecording() {
        audioRecorder.stop()
        recording = false
        showSheet = true

        let recording = Recording(fileURL: audioRecorder.url, createdAt: Date(), name: "New Recording")
        recordings.append(recording)
        currentRecordingID = recording.id
    }

    func getRecording(by id: UUID) -> Recording? {
        return recordings.first { $0.id == id }
    }

    func playRecording(id: UUID) {
        if let index = recordings.firstIndex(where: { $0.id == id }) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: recordings[index].fileURL)
                audioPlayer.delegate = self
                audioPlayer.numberOfLoops = repeatMode ? -1 : 0
                audioPlayer.play()
                recordings[index].isPlaying = true
            } catch {
                print("Could not play recording")
            }
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let index = recordings.firstIndex(where: { $0.fileURL == player.url }) {
            recordings[index].isPlaying = false
        }
    }

    func stopPlaying(id: UUID) {
        if let index = recordings.firstIndex(where: { $0.id == id }) {
            audioPlayer.stop()
            recordings[index].isPlaying = false
        }
    }

    func deleteRecording(recording: Recording) {
        // Remove recording from recordings array
        if let index = self.recordings.firstIndex(where: { $0.id == recording.id }) {
            self.recordings.remove(at: index)
        }

        // Remove file from file system
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: recording.fileURL)
        } catch {
            print("Failed to remove item: \(error)")
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
