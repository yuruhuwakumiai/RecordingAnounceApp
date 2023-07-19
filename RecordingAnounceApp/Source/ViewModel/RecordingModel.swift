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
    @objc dynamic var id = UUID().uuidString // 一意のID
    @objc dynamic var fileURL: String = "" // 録音ファイルのURL
    @objc dynamic var createdAt = Date() // 録音の作成日時
    @objc dynamic var isPlaying: Bool = false // 再生中かどうか
    @objc dynamic var name: String = "" // 録音の名前

    override static func primaryKey() -> String? {
        return "id" // 主キーとしてidを設定
    }
}

// MARK: - ViewModel
class RecorderViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    var realm: Realm // Realmデータベースのインスタンス
    @Published var recordings: Results<Recording> // 録音のリスト
    @Published var playingRecordingID: String? // 再生中の録音のID
    @Published var recording = false // 録音中かどうか
    @Published var repeatMode = false // リピートモードかどうか
    @Published var showAlert = false // アラートを表示するかどうか
    @Published var showSheet = false // シートを表示するかどうか
    @Published var repeatInterval: TimeInterval = 180 // リピート間隔（秒）
    @Published var isPlaying = false // 再生中かどうか
    private var cancellables = Set<AnyCancellable>() // Combineの購読を管理するための変数

    var audioRecorder: AVAudioRecorder! // 録音用のオブジェクト
    var audioPlayer: AVAudioPlayer! // 再生用のオブジェクト
    var currentRecordingID: String? // 現在録音中の録音のID
    var repeatTimer: Timer? // リピート再生用のタイマー

    override init() {
        realm = try! Realm() // Realmのインスタンスを作成
        recordings = realm.objects(Recording.self).sorted(byKeyPath: "createdAt", ascending: false) // 録音のリストを作成日時の降順で取得
        super.init()

        // リピート間隔が変更されたときにタイマーをリセットする
        $repeatInterval
            .sink { [weak self] newInterval in
                self?.resetRepeatTimer(interval: newInterval)
            }
            .store(in: &cancellables)

        // リピートモードがオフになったときにタイマーを無効にする
        $repeatMode
            .sink { [weak self] isOn in
                if !isOn {
                    self?.repeatTimer?.invalidate()
                    self?.repeatTimer = nil
                }
            }
            .store(in: &cancellables)

        // 再生状態が変更されたときに、リピートモードがオンならタイマーを設定し、オフならタイマーを無効にする
        $isPlaying
            .sink { [weak self] isPlaying in
                print("isPlaying changed to: \(isPlaying)")
                if !isPlaying && self?.repeatMode == true {
                    self?.repeatTimer = Timer.scheduledTimer(withTimeInterval: self?.repeatInterval ?? 180, repeats: false) { _ in
                        if let id = self?.playingRecordingID {
                            self?.playRecording(id: id)
                        }
                    }
                } else {
                    self?.repeatTimer?.invalidate()
                    self?.repeatTimer = nil
                }
            }
            .store(in: &cancellables)
    }

    // リピート再生用のタイマーをリセットするメソッド
    private func resetRepeatTimer(interval: TimeInterval) {
        repeatTimer?.invalidate()
        repeatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let id = self?.playingRecordingID else { return }
            self?.playRecording(id: id)
        }
    }

    // 録音を開始するメソッド
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

    // 録音を停止するメソッド
    func stopRecording() {
        audioRecorder.stop()
        recording = false
        showSheet = true

        let audioFileName = audioRecorder.url.lastPathComponent
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

    // IDによって録音を取得するメソッド
    func getRecording(by id: String) -> Recording? {
        return realm.object(ofType: Recording.self, forPrimaryKey: id)
    }

    // IDにされた音声を再生するメソ
    func playRecording(id: String) {
        if let recording = getRecording(by: id) {
            do {
                // 音声ファイい場所を指定
                let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let audioFileUrl = documentPath.appendingPathComponent(recording.fileURL)

                print("Trying to play audio file at: \(audioFileUrl)")

                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.playback)
                    try audioSession.setActive(true)

                    audioPlayer = try AVAudioPlayer(contentsOf: audioFileUrl)
                    audioPlayer.delegate = self
                    audioPlayer.numberOfLoops = 0

                    let prepared = audioPlayer.prepareToPlay()
                    print("Prepared to play: \(prepared)")

                    playingRecordingID = nil
                    print("Audio player status before play: \(audioPlayer.isPlaying)") // Add this line
                    audioPlayer.play()
                    print("Audio player status after play: \(audioPlayer.isPlaying)") // Add this line
                    isPlaying = true // Add this line

                    try realm.write {
                        recording.isPlaying = true
                    }

                    playingRecordingID = id

                    // Invalidate the repeat timer whenever a new recording starts playing
                    repeatTimer?.invalidate()
                    repeatTimer = nil
                } catch {
                    print("Could not play recording: \(error)")
                }
            }
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Finished playing audio")
        if let recording = realm.objects(Recording.self).filter("fileURL == %@", player.url!.lastPathComponent).first {
            do {
                try realm.write {
                    recording.isPlaying = false
                }
            } catch {
                print("Failed to update isPlaying status: \( error )")
            }
        }

        // Schedule the repeat timer whenever a recording finishes playing
        DispatchQueue.main.async { [weak self] in
            if self?.repeatMode == true, let id = self?.playingRecordingID {
                print("Scheduling next play") // Add this line
                self?.repeatTimer = Timer.scheduledTimer(withTimeInterval: self?.repeatInterval ?? 5, repeats: false) { _ in
                    print("Next play started") // Add this line
                    self?.playRecording(id: id)
                }
            } else {
                // Reset playingRecordingID and isPlaying when not in repeat mode
                self?.playingRecordingID = nil
                self?.isPlaying = false
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
