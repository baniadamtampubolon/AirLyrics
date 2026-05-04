//
//  TouchBarController.swift
//  Lyric Fever
//
//  Created by Antigravity on 2026-05-01.
//

import Cocoa
import SwiftUI

extension NSTouchBarItem.Identifier {
    static let lyricControlStripItem = NSTouchBarItem.Identifier("com.adamtampubolon.lyricfever.controlstrip")
    static let lyricModalItem = NSTouchBarItem.Identifier("com.adamtampubolon.lyricfever.modalitem")
}

@MainActor
class TouchBarController: NSObject, NSTouchBarDelegate {
    static let shared = TouchBarController()
    
    var customItem: NSCustomTouchBarItem?
    var lyricButton: NSButton?
    
    // Modal Touch Bar elements
    var systemTouchBar: NSTouchBar?
    var modalLyricButton: NSButton?
    var isPresentingModal = false
    
    // Private APIs
    typealias DFRSystemModalShowsCloseBoxWhenFrontMostFunc = @convention(c) (Bool) -> Void
    typealias DFRElementSetControlStripPresenceForIdentifierFunc = @convention(c) (NSTouchBarItem.Identifier, Bool) -> Void
    
    private var dfrSystemModalShowsCloseBoxWhenFrontMost: DFRSystemModalShowsCloseBoxWhenFrontMostFunc?
    private var dfrElementSetControlStripPresenceForIdentifier: DFRElementSetControlStripPresenceForIdentifierFunc?
    
    private override init() {
        super.init()
        loadPrivateAPIs()
    }
    
    private func loadPrivateAPIs() {
        let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
        
        let dfrHandle = dlopen("/System/Library/PrivateFrameworks/DFRFoundation.framework/Versions/A/DFRFoundation", RTLD_LAZY)
        let handleToUse = dfrHandle ?? RTLD_DEFAULT
        
        if let sym = dlsym(handleToUse, "DFRSystemModalShowsCloseBoxWhenFrontMost") {
            self.dfrSystemModalShowsCloseBoxWhenFrontMost = unsafeBitCast(sym, to: DFRSystemModalShowsCloseBoxWhenFrontMostFunc.self)
            print("Loaded DFRSystemModalShowsCloseBoxWhenFrontMost")
        }
        
        if let sym = dlsym(handleToUse, "DFRElementSetControlStripPresenceForIdentifier") {
            self.dfrElementSetControlStripPresenceForIdentifier = unsafeBitCast(sym, to: DFRElementSetControlStripPresenceForIdentifierFunc.self)
            print("Loaded DFRElementSetControlStripPresenceForIdentifier")
        }
    }
    
    func setupControlStrip() {
        dfrSystemModalShowsCloseBoxWhenFrontMost?(true)
        
        let item = NSCustomTouchBarItem(identifier: .lyricControlStripItem)
        
        // Tombol di Control Strip cukup menampilkan icon 🎵 agar tidak memakan tempat
        let button = NSButton(title: "🎵", target: self, action: #selector(buttonClicked))
        button.bezelStyle = .rounded
        
        item.view = button
        self.customItem = item
        self.lyricButton = button
        
        // Add to system tray using Obj-C runtime
        let addSelector = NSSelectorFromString("addSystemTrayItem:")
        if NSTouchBarItem.responds(to: addSelector) {
            NSTouchBarItem.perform(addSelector, with: item)
            print("Successfully called addSystemTrayItem:")
        } else {
            print("NSTouchBarItem does not respond to addSystemTrayItem:")
        }
        
        if let dfrElementSetControlStripPresenceForIdentifier = dfrElementSetControlStripPresenceForIdentifier {
            dfrElementSetControlStripPresenceForIdentifier(.lyricControlStripItem, true)
            print("Successfully called DFRElementSetControlStripPresenceForIdentifier")
        } else {
            print("Failed to call DFRElementSetControlStripPresenceForIdentifier")
        }
    }
    
    @objc func buttonClicked() {
        toggleModalTouchBar()
    }
    
    func toggleModalTouchBar() {
        if isPresentingModal {
            let dismissSelector = NSSelectorFromString("dismissSystemModalTouchBar:")
            if NSTouchBar.responds(to: dismissSelector) {
                NSTouchBar.perform(dismissSelector, with: self.systemTouchBar)
            }
            isPresentingModal = false
        } else {
            if systemTouchBar == nil {
                let tb = NSTouchBar()
                tb.delegate = self
                tb.defaultItemIdentifiers = [.lyricModalItem]
                self.systemTouchBar = tb
            }
            
            let presentSelector = NSSelectorFromString("presentSystemModalTouchBar:systemTrayItemIdentifier:")
            if NSTouchBar.responds(to: presentSelector) {
                NSTouchBar.perform(presentSelector, with: self.systemTouchBar, with: NSTouchBarItem.Identifier.lyricControlStripItem.rawValue)
            }
            isPresentingModal = true
        }
    }
    
    // MARK: - NSTouchBarDelegate
    nonisolated func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        if identifier == .lyricModalItem {
            let item = NSCustomTouchBarItem(identifier: identifier)
            
            DispatchQueue.main.async {
                let button = NSButton(title: "🎵 Lyric Fever", target: self, action: #selector(self.modalButtonClicked))
                button.bezelStyle = .rounded
                // Hilangkan background agar terlihat lebih natural seperti teks berjalan
                button.isBordered = false
                button.font = NSFont.systemFont(ofSize: 14, weight: .medium)
                
                item.view = button
                self.modalLyricButton = button
            }
            
            return item
        }
        return nil
    }
    
    @objc func modalButtonClicked() {
        // Jika lirik di-klik, tutup modalnya dan kembalikan Touch Bar ke aplikasi sebelumnya
        toggleModalTouchBar()
    }
    
    func updateLyric(text: String?) {
        let displayText = (text != nil && !text!.isEmpty) ? text! : "Lyric Fever"
        
        // Update teks di modal (layar penuh Touch Bar)
        self.modalLyricButton?.title = displayText
        
        // Tampilkan layar penuh secara otomatis jika ada lirik dan belum tampil
        if text != nil && !text!.isEmpty && !isPresentingModal {
            toggleModalTouchBar()
        } 
        // Sembunyikan otomatis jika lirik kosong/musik berhenti
        else if (text == nil || text!.isEmpty) && isPresentingModal {
            toggleModalTouchBar()
        }
    }
}


