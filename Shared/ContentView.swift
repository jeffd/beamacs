//
//  ContentView.swift
//  Shared
//
//  Created by Jeff Dlouhy on 12/10/21.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: beamacsDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(beamacsDocument()))
    }
}
