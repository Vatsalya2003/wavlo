import Foundation
import Speech
import AVFoundation
import os.log
import Combine

@MainActor
final class VoiceInputService: ObservableObject {

    private let logger = Logger(subsystem: "com.wavlo", category: "VoiceInput")
    private let recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @Published var isAuthorized = false
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?

    init(locale: Locale = .current) {
        self.recognizer = SFSpeechRecognizer(locale: locale)
    }

    func requestAuthorization() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                Task { @MainActor in
                    switch status {
                    case .authorized:
                        self?.isAuthorized = true
                    case .denied:
                        self?.errorMessage = "Speech recognition denied"
                    case .restricted:
                        self?.errorMessage = "Speech recognition restricted"
                    case .notDetermined:
                        self?.errorMessage = "Speech recognition not determined"
                    @unknown default:
                        break
                    }
                    continuation.resume()
                }
            }
        }
    }

    func startListening() async {
        guard isAuthorized, let recognizer = recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer not available"
            return
        }
        guard !isListening else { return }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }
        request.shouldReportPartialResults = true
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
            transcribedText = ""
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    if let result = result {
                        self?.transcribedText = result.bestTranscription.formattedString
                    }
                    if result?.isFinal == true || error != nil {
                        self?.stopListening()
                    }
                }
            }
        } catch {
            logger.error("Voice start failed: \(String(describing: error))")
            errorMessage = error.localizedDescription
        }
    }

    func stopListening() {
        guard isListening else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
}

