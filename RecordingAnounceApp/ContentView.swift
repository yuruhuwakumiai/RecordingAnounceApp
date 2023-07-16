//
//  ContentView.swift
//  RecordingAnounceApp
//
//  Created by 橋元雄太郎 on 2023/07/16.
//

import SwiftUI

// MARK: - View
struct ContentView: View {
    @ObservedObject var recorderViewModel = RecorderViewModel()
    @State private var newRecordingName: String = "名無し"

    var body: some View {
        VStack {
            List {
                Section(header: Text("Recordings")) {
                    ForEach(recorderViewModel.recordings) { recording in
                        RecordingRowView(recorderViewModel: recorderViewModel, recordingID: recording.id)
                    }
                    .onDelete(perform: delete)
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
                Text("名前をつけてやれ！！")
                TextField("なまえ", text: $newRecordingName)
                Button(action: {
                    if let id = recorderViewModel.currentRecordingID,
                       let index = recorderViewModel.recordings.firstIndex(where: { $0.id == id }) {
                        recorderViewModel.recordings[index].name = newRecordingName
                    }
                    recorderViewModel.showSheet = false
                }) {
                    Text("保存する")
                }
            }
            .padding()
        }
    }

    func delete(at offsets: IndexSet) {
        offsets.forEach { index in
            let recording = recorderViewModel.recordings[index]
            recorderViewModel.deleteRecording(recording: recording)
        }
    }
}

struct RecordingRowView: View {
    @ObservedObject var recorderViewModel: RecorderViewModel
    var recordingID: UUID

    var body: some View {
        if let recording = recorderViewModel.getRecording(by: recordingID) {
            HStack {
                Text("\(recording.name)")
                Spacer()
                Button(action: {
                    if recording.isPlaying {
                        self.recorderViewModel.stopPlaying(id: recordingID)
                    } else {
                        self.recorderViewModel.playRecording(id: recordingID)
                    }
                }) {
                    Image(systemName: recording.isPlaying ? "stop.circle" : "play.circle")
                }
                .buttonStyle(PlainButtonStyle()) // Add this
                .contentShape(Rectangle()) // Make sure only this button is tappable

                Button(action: {
                    recorderViewModel.currentRecordingID = recording.id
                    recorderViewModel.showSheet = true
                }) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(PlainButtonStyle()) // Add this
                .contentShape(Rectangle()) // Make sure only this button is tappable
            }
        }
    }
}





struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
