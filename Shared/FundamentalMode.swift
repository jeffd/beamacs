//
//  Mode.swift
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
import SwiftUI

/// A mode encapsulates how keystrokes map to a command for the current document.
protocol Mode: AnyObject, Documentable {
  var commandTable: CommandTable { get set }
  var currentDocument: beamacsDocument? { get set }
  var currentSelections: [NSRange] { get set }

  /// Bind a shortcut to a command
  func defineShortcut(_ shortcut: KeyboardShortcut, _ command: @escaping CommandThunk)
  func command(for shortcut: KeyboardShortcut) throws -> Command
}

extension Mode {
  func defineShortcut(_ shortcut: KeyboardShortcut, _ command: @escaping CommandThunk) {
    commandTable.commands[shortcut] = .init(command: command, commandTable: nil)
  }
}

/// The base mode that can edit text
class FundamentalMode: Mode {
  var name: String = "Fundamental Mode"
  var description: String = "The basic mode for editing text"
  var commandTable = CommandTable(name: "Text Commands", description: "Basic text editing commands")

  var currentDocument: beamacsDocument?
  var currentSelections: [NSRange] = []

  init() {
    setupCommands()
  }

  func setupCommands() {

  }

  func command(for shortcut: KeyboardShortcut) throws -> Command {
    // First lookup the shortcut in our command table
    if let comtabCommand = commandTable.commands[shortcut] {
      return try comtabCommand.command()
    }

    // Regular keys might not be mapped to keys by default, so we'll fallback and make them
    // self inserting keys.
    if let firstCharScalar = shortcut.key.character.unicodeScalars.first,
       CharacterSet.alphanumerics.contains(firstCharScalar),
       shortcut.modifiers.isDisjoint(with: .all) {
      return try self.makeInsertKeyCommand(shortcut)
    }

    throw CommandError.notFound
  }

  func makeInsertKeyCommand(_ shortcut: KeyboardShortcut) throws -> Command {
    guard let textContentStorage = currentDocument?.textContentStorage else { throw CommandError.documentNil }
    let keyToInsert = NSAttributedString(string: String(shortcut.key.character))

    let modifyAction = try modify(textContentStorage, in: currentSelections, with: keyToInsert)
    return Command(name: "self-insert-\(keyToInsert.string)",
                   description: "A self inserting character key",
                   lastExecuted: Date(),
                   action: modifyAction.thunk,
                   inverseAction: modifyAction.inverse)
  }
  
  @discardableResult
  func modify(_ textContentStorage: NSTextContentStorage, in ranges: [NSRange], with string: NSAttributedString) throws -> (thunk: (() -> Void), inverse: (() -> Void)) {
    // Note: For demo purposes, we'll keep it simple and just deal with one selection range, assuming one user.
    guard let firstRange = ranges.first else { throw CommandError.invalidRange }
    let previousContents = textContentStorage.textStorage?.attributedSubstring(from: firstRange)
    let rangeAfterModification = NSRange(location: firstRange.location, length: string.length)

    let thunk: (() -> Void) = {
      print("Insert \(string)")
      textContentStorage.performEditingTransaction {
        textContentStorage.textStorage?.replaceCharacters(in: firstRange, with: string)
      }
    }

    let inverse: (() -> Void) = {
      print("Undo Insert of \(string)")
      textContentStorage.performEditingTransaction {
        if let previousContents = previousContents {
          textContentStorage.textStorage?.replaceCharacters(in: rangeAfterModification, with: previousContents)
        } else {
          print("previous contents empty")
        }
      }
    }

    return (thunk, inverse)
  }

}
