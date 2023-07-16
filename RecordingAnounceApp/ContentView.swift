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

    var body: some View {
        VStack {
            List {
                Section(header: Text("Recordings")) {
                    ForEach(recorderViewModel.recordings, id: \.createdAt) { recording in
                        RecordingRowView(recorderViewModel: recorderViewModel, recording: recording)
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationBarTitle("Voice recorder")

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
    var recording: Recording

    var body: some View {
        HStack {
            Text("\(recording.createdAt.toString(dateFormat: "dd-MM-YY 'at' HH:mm:ss"))")
            Spacer()
            Button(action: {
                self.recorderViewModel.playRecording(recording: recording)
            }) {
                Image(systemName: "play.circle")
            }
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
