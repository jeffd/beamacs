//
//  beamacsApp.swift
//  Shared
//
//  Created by Jeff Dlouhy on 12/10/21.
//

import SwiftUI

@main
struct beamacsApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: beamacsDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
