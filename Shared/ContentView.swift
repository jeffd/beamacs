//
//  ContentView.swift
//  Shared
//
//  Created by Jeff Dlouhy on 12/10/21.
//
//  Copyright (C) 2021 Jeff Dlouhy
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

import SwiftUI

// MARK: - ContentView

struct ContentView: View {
  @Binding var document: beamacsDocument
  @ObservedObject var commandReader = CommandReader()

  var body: some View {
    BufferView(document.textContentStorage, commandReader: commandReader)
      .onAppear {
        commandReader.currentMode.currentDocument = document
      }
  }
}


// MARK: - ContentView_Previews

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(document: .constant(beamacsDocument()))
  }
}
