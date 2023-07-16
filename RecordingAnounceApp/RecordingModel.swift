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
struct Recording {
    let fileURL: URL
    let createdAt: Date
}

// MARK: - ViewModel
class RecorderViewModel: ObservableObject {
    @Published var recordings = [Recording]()
    @Published var recording = false

    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!

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

        let recording = Recording(fileURL: audioRecorder.url, createdAt: Date())
        recordings.append(recording)
    }

    func playRecording(recording: Recording) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            audioPlayer.play()
        } catch {
            print("Could not play recording")
        }
    }

    func stopPlaying() {
        audioPlayer.stop()
    }

    func deleteRecording(recording: Recording) {
        // Remove recording from recordings array
        if let index = self.recordings.firstIndex(where: { $0.fileURL == recording.fileURL }) {
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
