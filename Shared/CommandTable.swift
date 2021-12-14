//
//  CommandTable.swift
//  beamacs
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

import Foundation
import SwiftUI

typealias CommandThunk = (() throws -> Command)

/// A lookup table of keystrokes to commands.
struct CommandTable: Documentable, Hashable {
  let name: String
  let description: String

  var commands: [KeyboardShortcut: KeystrokeResult] = .init()

  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(description)
    commands.keys.forEach { hasher.combine($0) }
  }

  static func == (lhs: CommandTable, rhs: CommandTable) -> Bool {
    lhs.hashValue == rhs.hashValue
  }
}

/// A KeystrokeResult is a keyboard shortcut that maps to a command
/// or another command table to dispatch on.
struct KeystrokeResult {
  let command: CommandThunk
  let commandTable: CommandTable?
}
