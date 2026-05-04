//
//  TouchBarView.swift
//  Lyric Fever
//
//  Created by Antigravity on 2026-05-01.
//

import SwiftUI

struct TouchBarView: View {
    @Environment(ViewModel.self) var viewmodel
    
    var lyricText: String? {
        if viewmodel.userDefaultStorage.hasOnboarded {
            if viewmodel.isPlaying, viewmodel.showLyrics, let currentlyPlayingLyricsIndex = viewmodel.currentlyPlayingLyricsIndex {
                if viewmodel.translationExists {
                    return viewmodel.translatedLyric[currentlyPlayingLyricsIndex]
                } else if !viewmodel.romanizedLyrics.isEmpty {
                    return viewmodel.romanizedLyrics[currentlyPlayingLyricsIndex]
                } else if !viewmodel.chineseConversionLyrics.isEmpty {
                    return viewmodel.chineseConversionLyrics[currentlyPlayingLyricsIndex]
                } else {
                    return viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words
                }
            } else if let currentlyPlayingName = viewmodel.currentlyPlayingName, let currentlyPlayingArtist = viewmodel.currentlyPlayingArtist {
                return "\(currentlyPlayingName) - \(currentlyPlayingArtist)"
            }
        }
        return nil
    }

    var body: some View {
        Button(action: {
            // Do nothing
        }) {
            if let lyricText {
                Text(lyricText)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .padding(.horizontal)
            } else {
                Text("Lyric Fever")
                    .italic()
            }
        }
    }
}
