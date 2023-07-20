//
//  ContentView.swift
//  RecordingAnounceApp
//
//  Created by 橋元雄太郎 on 2023/07/16.
//

import SwiftUI
import RealmSwift

// MARK: - View
struct ContentView: View {
    @ObservedObject var recorderViewModel = RecorderViewModel()
    @State private var newRecordingName: String = "名無し"
    @State private var repeatIntervalText: String = "10"

    var body: some View {
        VStack {
            List {
                Section(header: Text("Recordings")) {
                    ForEach(Array(recorderViewModel.recordings), id: \.id) { recording in
                        RecordingRowView(recorderViewModel: recorderViewModel, recordingID: recording.id)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            let recording = self.recorderViewModel.recordings[index]
                            let id = recording.id
                            self.recorderViewModel.deleteRecording(id: id)
                        }
                        // Update the recordings
                        self.recorderViewModel.recordings = self.recorderViewModel.realm.objects(Recording.self).sorted(byKeyPath: "createdAt", ascending: false)
                    }
                }
            }

            HStack {
                Spacer()

                Toggle(isOn: $recorderViewModel.repeatMode) {
                    Text("Repeat Mode")
                }
                .padding()

                TextField("Repeat Interval", text: $repeatIntervalText, onCommit: {
                    if let interval = TimeInterval(repeatIntervalText) {
                        recorderViewModel.repeatInterval = interval
                    }
                })
                .keyboardType(.numberPad)
                .frame(height: 50)
                .frame(width: 80)
                .background(Color.white) // 背景色を白に設定
                .multilineTextAlignment(.center) // 右詰に設定
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1)) // 枠線を追加

                Spacer()
            }

            ZStack {
                if self.recorderViewModel.recording {
                    PulsingAnimation()
                        .frame(width: 110, height: 110)
                }

                Circle()
                    .stroke(lineWidth: 20)
                    .frame(width: 100, height: 100)
                    .foregroundColor(self.recorderViewModel.recording ? .red : .green)

                Button(action: {
                    if self.recorderViewModel.recording {
                        self.recorderViewModel.stopRecording()
                    } else {
                        self.recorderViewModel.startRecording()
                    }
                }) {
                    Image(systemName: "mic.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 76, height: 76)
                        .foregroundColor(.black)
                }
            }
            .padding(.all, 10)
            .padding(.bottom, 10)

            Text(self.recorderViewModel.recording ? "録音中" : "タップして声(魂)を吹き込め！")
                .font(.title3)
                .foregroundColor(self.recorderViewModel.recording ? .red : .black)
        }
        .background(.yellow) //　画面下部の背景色
        .sheet(isPresented: $recorderViewModel.showSheet) {
            VStack {
                Spacer()
                Text("名前をつけてやれ！！")
                    .font(.title)
                    .padding()
                TextField("なまえ", text: $newRecordingName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                Button(action: {
                    if let id = recorderViewModel.currentRecordingID,
                       let recording = recorderViewModel.realm.object(ofType: Recording.self, forPrimaryKey: id) {
                        try? recorderViewModel.realm.write {
                            recording.name = newRecordingName
                        }
                        recorderViewModel.showSheet = false
                    }
                }) {
                    Text("保存する")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.blue)
                        .cornerRadius(10.0)
                }
                Spacer()
            }
            .padding()
        }
    }

    func delete(at offsets: IndexSet) {
        offsets.forEach { index in
            let recording = recorderViewModel.recordings[index]
            recorderViewModel.deleteRecording(id: recording.id)
        }
    }
}

struct RecordingRowView: View {
    @ObservedObject var recorderViewModel: RecorderViewModel
    
    var recordingID: String

    var body: some View {
        if let recording = recorderViewModel.getRecording(by: recordingID) {
            HStack {
                Text("\(recording.name)")
                Spacer()
                Button(action: {
                    if self.recorderViewModel.playingRecordingID == recording.id {
                        self.recorderViewModel.stopPlaying(id: recording.id)
                    } else {
                        self.recorderViewModel.playRecording(id: recording.id)
                    }
                }) {
                    Image(systemName: self.recorderViewModel.playingRecordingID == recording.id ? "stop.circle.fill" : "play.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(self.recorderViewModel.playingRecordingID == recording.id ? .green : .blue)
                        .frame(width: 25, height: 25)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .padding()

                Button(action: {
                    recorderViewModel.currentRecordingID = recording.id
                    recorderViewModel.showSheet = true
                }) {
                    Image(systemName: "pencil")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
        }
    }
}

struct PulsingAnimation: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Color.red.opacity(0.3))
            .scaleEffect(isAnimating ? 1 : 0.6)
            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true))
            .onAppear {
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
