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
    @State private var newRecordingName: String = ""

    var body: some View {
        VStack {
            List {
                Section(header: Text("Recordings")) {
                    ForEach(Array(zip(recorderViewModel.recordings.indices, recorderViewModel.recordings)), id: \.1.createdAt) { index, _ in
                        RecordingRowView(recorderViewModel: recorderViewModel, index: index)
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

            Text(self.recorderViewModel.recording ? "俺に負けるなよ！" : "Tap to record")
                .font(.title)
                .foregroundColor(self.recorderViewModel.recording ? .red : .black)
        }
        .sheet(isPresented: $recorderViewModel.showSheet) {
            VStack {
                Text("名前をつけてあげよう")
                TextField("Name", text: $newRecordingName)
                Button(action: {
                    if let index = recorderViewModel.currentRecordingIndex {
                        recorderViewModel.recordings[index].name = newRecordingName
                    }
                    recorderViewModel.showSheet = false
                }) {
                    Text("Save")
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
    var index: Int

    var body: some View {
        HStack {
            Text("\(recorderViewModel.recordings[index].name)")
            Spacer()
            Button(action: {
                if recorderViewModel.recordings[index].isPlaying {
                    self.recorderViewModel.stopPlaying(index: index)
                } else {
                    self.recorderViewModel.playRecording(index: index)
                }
            }) {
                Image(systemName: recorderViewModel.recordings[index].isPlaying ? "stop.circle" : "play.circle")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
