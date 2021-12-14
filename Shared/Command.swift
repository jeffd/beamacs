//
//  Command.swift
//  beamacs
//
//  Created by Jeff Dlouhy on 12/14/21.
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

protocol Documentable {
  /// The human readable name of an item
  var name: String { get }
  /// A human readable description an item
  var description: String { get }
}

/// If something is undoable, it has a function which will be the
/// opposite of the previous state.
protocol Undoable {
  /// The time at which the command was initiated
  var lastExecuted: Date { get }
  /// The opposite of the original action (aka 'cancel')
  var inverseAction: (() -> Void) { get }
}

struct Command: Hashable, Equatable, Documentable, Undoable {
  private let id = UUID()
  var lastExecuted: Date
  let name: String
  let description: String

  /// The possible state mutating action of the command
  var action: (() -> Void)
  /// The inverse of the `action` which will revert to the previous state.
  /// Since the information needed for the action is the same information
  /// needed for the reversion, state can be stored in this closure at definition time.
  var inverseAction: (() -> Void)

  func hash(into hasher: inout Hasher) {
    hasher.combine(lastExecuted)
    hasher.combine(name)
    hasher.combine(description)
    hasher.combine(id)
  }

  static func == (lhs: Command, rhs: Command) -> Bool {
    lhs.hashValue == rhs.hashValue
  }
}
