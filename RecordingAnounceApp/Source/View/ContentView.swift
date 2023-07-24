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
    @State private var newRecordingName: String = "放送に名前をつけましょう"
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

                Toggle(isOn: $recorderViewModel.repeatMode) {
                    Text("Repeat Mode")
                }
                .padding()

                NumberTextField(text: $repeatIntervalText) {
                    if let interval = TimeInterval(repeatIntervalText) {
                        recorderViewModel.repeatInterval = interval
                    }
                }
                .frame(height: 50)
                .frame(width: 80)
                .background(Color.white)
                .multilineTextAlignment(.center)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray, lineWidth: 1))

                Text("秒")
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

            Text(self.recorderViewModel.recording ? "放送を録音中" : "タップして放送を録音")
                .font(.title3)
                .foregroundColor(self.recorderViewModel.recording ? .red : .black)
        }
        .background(.yellow) //　画面下部の背景色
        .sheet(isPresented: $recorderViewModel.showSheet) {
            VStack {
                Spacer()
                Text("名称変更")
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
                        .frame(width: 40, height: 40)
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
            .scaleEffect(isAnimating ? 1 : 0.3)
            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true))
            .onAppear {
                isAnimating = true
            }
            .onDisappear {
                isAnimating = false
            }
    }
}

struct NumberTextField: UIViewRepresentable {
    @Binding var text: String
    var onCommit: (() -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.delegate = context.coordinator
        textField.textAlignment = .center  // テキストをセンターに配置

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.doneButtonTapped))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flexSpace, doneButton]

        textField.inputAccessoryView = toolbar
        context.coordinator.textField = textField  // textFieldの参照を保存
        return textField
    }


    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NumberTextField
        var textField: UITextField?  // UITextFieldの参照を保持するプロパティを追加

        init(_ parent: NumberTextField) {
            self.parent = parent
        }

        @objc func doneButtonTapped() {
            parent.text = textField?.text ?? ""  // textFieldのテキストをparent.textに設定
            parent.onCommit?()
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
