//
//  AudioPlayerViewModel.swift
//  audioopus
//
//  Created by intiser Ahmed on 07/07/2024.
//
import AVFAudio
import AVFoundation
import Foundation
import Opus
import SwiftOGG
import SwiftUI

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    private var player: PCMPlayer?
    private var pcmData: Data?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    private var timer: Timer?
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func loadAudio() {
        guard let url = Bundle.main.url(forResource: "homeaudio", withExtension: "opus") else {
            print("Audio file not found")
            return
        }
        
        do {
            let opusData = try Data(contentsOf: url)
            let decoder = try OGGDecoder(audioData: opusData)
            pcmData = decoder.pcmData
            
            let sampleRate = Double(16000)
            let channels = AVAudioChannelCount(2)
            player = PCMPlayer(sampleRate: sampleRate, channels: channels)
            
            let bytesPerSample = 2 // Assuming 16-bit samples
            let totalSamples = pcmData!.count / (bytesPerSample * Int(channels))
            print(totalSamples)
            print(sampleRate)

            duration = Double(totalSamples) / sampleRate
            
            print("Sample Rate: \(sampleRate)")
            print("Channels: \(channels)")
            print("PCM Data Size: \(pcmData!.count) bytes")
            print("Calculated Duration: \(duration) seconds")
        } catch {
            print("Failed to load audio: \(error)")
        }
    }
    
    func play() {
        guard let player = player, let pcmData = pcmData else { return }
        player.play(pcmData: pcmData)
        isPlaying = true
        startTimeObserver()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopTimeObserver()
    }
    
    func seek(to time: Double) {
        guard let pcmData = pcmData else { return }
        let bytesPerSecond = 44100 * 2 * 1 // Assuming 44.1kHz, 16-bit samples, stereo
        let byteOffset = Int(time * Double(bytesPerSecond))
        let remainingData = pcmData.subdata(in: byteOffset ..< pcmData.count)
        player?.play(pcmData: remainingData)
        currentTime = time
    }
    
    private func startTimeObserver() {
        stopTimeObserver()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            self.currentTime += 0.1
            if self.currentTime >= self.duration {
                self.pause()
                self.currentTime = 0
            }
        }
    }
    
    private func stopTimeObserver() {
        timer?.invalidate()
        timer = nil
    }
}

class PCMPlayer {
    private var audioEngine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var audioFormat: AVAudioFormat

    init(sampleRate: Double, channels: AVAudioChannelCount) {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        audioEngine.attach(playerNode)

        audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channels)!
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
    }

    func play(pcmData: Data) {
        let frameCount = pcmData.count / Int(audioFormat.streamDescription.pointee.mBytesPerFrame)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = buffer.frameCapacity

        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        pcmData.withUnsafeBytes { (pcmBufferPointer: UnsafeRawBufferPointer) in
            let bufferPointer = pcmBufferPointer.bindMemory(to: UInt8.self)
            memcpy(audioBuffer.mData, bufferPointer.baseAddress, pcmData.count)
        }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
        playerNode.play()
    }

    func pause() {
        playerNode.pause()
    }
}
