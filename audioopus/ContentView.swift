//
//  ContentView.swift
//  audioopus
//
//  Created by intiser Ahmed on 05/07/2024.
//
import AVFoundation
import SwiftOGG
import SwiftUI

@available(iOS 14.0, *)
struct ContentView: View {
    @StateObject private var audioManager = AudioManager.shared
    
    var body: some View {
        VStack {
            Text("Opus Player")
                .font(.title)
                .padding()
            
            Button(action: {
                if audioManager.isPlaying {
                    audioManager.pause()
                } else {
                    audioManager.play()
                }
            }) {
                Image(systemName: audioManager.isPlaying ? "pause.circle" : "play.circle")
                    .font(.system(size: 50))
            }
            
            Slider(value: $audioManager.currentTime, in: 0 ... audioManager.duration) { editing in
                if !editing {
                    audioManager.seek(to: audioManager.currentTime)
                }
            }
            
            Text(String(format: "%.2f / %.2f", audioManager.currentTime, audioManager.duration))
        }
        .padding()
        .onAppear {
            audioManager.loadAudio()
        }
    }
}
