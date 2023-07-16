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
            .navigationBarTitle("Voice recorder")

            Toggle(isOn: $recorderViewModel.repeatMode) {
                Text("Repeat Mode")
            }
            .padding()

            ZStack {
                Circle()
                    .stroke(lineWidth: 20)
                    .frame(width: 100, height: 100)
                    .foregroundColor(self.recorderViewModel.recording ? .red : .gray)
                    .animation(.default)

                if self.recorderViewModel.recording {
                    Button(action: {
                        self.recorderViewModel.stopRecording()
                    }) {
                        Image("murakoRe")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 76, height: 76)
                            .foregroundColor(.black)
                    }
                    .scaleEffect(1.3)
                    .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true))
                } else {
                    Button(action: {
                        self.recorderViewModel.startRecording()
                    }) {
                        Image(systemName: "mic.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 76, height: 76)
                            .foregroundColor(.black)
                    }
                    .scaleEffect(1.1)
                    .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true))
                }
            }
            .padding(.all, 10)
            .padding(.bottom, 10)

            Text(self.recorderViewModel.recording ? "俺に負けるなよ！" : "タップして声(魂)を吹き込め！")
                .font(.title)
                .foregroundColor(self.recorderViewModel.recording ? .red : .black)

        }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
