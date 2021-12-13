//
//  CommandReader.swift
//  beamacs
//
//  Created by Jeff Dlouhy on 12/11/21.
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
import Combine
import Collections
import Algorithms

enum CommandError: Error {
  case documentNil
  case noMoreUndo
  case noMoreRedo
  case invalidRange
}

class CommandReader: NSObject, ObservableObject {
  private static let maxCommandGroupingDelta: TimeInterval = 2

  let latestKeyDown: PassthroughSubject<KeyboardShortcut, Never> = .init()
  let latestSelection: PassthroughSubject<TextSelectionChange, Never> = .init()

  private var keyDownSubscriber: AnyCancellable?
  private var selectionSubscriber: AnyCancellable?

  private var undoStack: Deque<Command> = .init()
  private var redoStack: Deque<Command> = .init()

  var currentDocument: beamacsDocument?
  private var currentSelections: [NSRange] = .init()

  override init() {
    super.init()
    keyDownSubscriber = latestKeyDown
      .receive(on: RunLoop.main)
      .sink(receiveValue: { shortcut in
        //print("Command Reader Got Shortcut: \(shortcut.key.character)")
        self.dispatchOnShortcut(shortcut)
      })

    selectionSubscriber = latestSelection
      .receive(on: RunLoop.main)
      .sink(receiveValue: { latestChange in
        print("Got selection change")
        // Add it to the queue
        self.currentSelections = latestChange.to
        //self.pushCommand(self.makeChangeSelectionCommand(latestChange))
      })

  }

  let undoShortcut = KeyboardShortcut("z", modifiers: .command, localization: .automatic)
  let redoShortcut = KeyboardShortcut("r", modifiers: [.command, .shift] , localization: .automatic)

  func dispatchOnShortcut(_ shortcut: KeyboardShortcut) {
    guard let firstCharScalar = shortcut.key.character.unicodeScalars.first else { return }

    switch shortcut.key.character {
    case "z":
      print("Undo!")
      do {
        try undoNextGroup(with: Self.maxCommandGroupingDelta)
      } catch {
        __NSBeep()
      }
      return
    case "r":
      print("Redo!")
      do {
        try redoNextGroup(with: Self.maxCommandGroupingDelta)
      } catch {
        __NSBeep()
      }
      return
    default:
      break
    }

    if CharacterSet.alphanumerics.contains(firstCharScalar), shortcut.modifiers.isDisjoint(with: .all) {
      print("IS A SELF INSERTING KEY")
      if let newCommand = try? self.makeInsertKeyCommand(shortcut) {
        pushCommand(newCommand)
      }
    }
  }

  private func pushCommand(_ command: Command) {
    // Wipe the redo stack?
    redoStack.removeAll()

    // Run the command
    command.action()
    // Add it to the undo stack
    undoStack.prepend(command)
  }

  /// Determine if the two commands were executed with a time range for the given delta
  /// - Parameters:
  ///   - lhs: A Command
  ///   - rhs: A Command
  ///   - delta: The maximum difference to allow between dates
  /// - Returns: If the two commands had dates under the given time interval delta.
  private func commandsUnderTimeIntervalDelta(lhs: Command, rhs: Command, delta: TimeInterval) -> Bool {
    abs(lhs.lastExecuted.timeIntervalSince(rhs.lastExecuted)) < delta
  }

  /// Pop the next group of commands from the undo stack to the redo stack.
  /// This will execute the inverse function of the command.
  ///
  /// - Parameter maxDelta: The time difference to determine the next group of commands.
  private func undoNextGroup(with maxDelta: TimeInterval) throws {
    // Lazily chunk the stack by time intervals under the delta.
    let chunkedUndo = undoStack
      .lazy
      .chunked { self.commandsUnderTimeIntervalDelta(lhs: $0, rhs: $1, delta: maxDelta) }
      .first

    // We only get the first grouped chunk and will pop the stack for each item.
    guard var firstGroupCount = chunkedUndo?.count else { throw CommandError.noMoreUndo }

    while firstGroupCount > 0 {
      guard let poppedUndoCommand = undoStack.popFirst() else { throw CommandError.noMoreUndo }
      poppedUndoCommand.inverseAction()
      redoStack.prepend(poppedUndoCommand)
      firstGroupCount -= 1
    }
  }

  /// Pop the next group of commands from the redo stack to the undo stack.
  /// This will execute the original action function of the command.
  ///
  /// - Parameter maxDelta: The time difference to determine the next group of commands.
  private func redoNextGroup(with maxDelta: TimeInterval) throws {
    let chunkedRedo = redoStack
      .lazy
      .chunked { self.commandsUnderTimeIntervalDelta(lhs: $0, rhs: $1, delta: maxDelta) }
      .first

    guard var firstGroupCount = chunkedRedo?.count else { throw CommandError.noMoreRedo }

    while firstGroupCount > 0 {
      guard let poppedRedoCommand = redoStack.popFirst() else { throw CommandError.noMoreRedo }
      poppedRedoCommand.action()
      undoStack.prepend(poppedRedoCommand)
      firstGroupCount -= 1
    }
  }

  func makeInsertKeyCommand(_ shortcut: KeyboardShortcut) throws -> Command {
    guard let textContentStorage = currentDocument?.textContentStorage,
          let documentLength = textContentStorage.textStorage?.length else { throw CommandError.documentNil }

    let keyToInsert = NSAttributedString(string: String(shortcut.key.character))

    let modifyAction = try modify(textContentStorage, in: currentSelections, with: keyToInsert)
    return Command(lastExecuted: Date(),
                   name: "self-insert-\(keyToInsert.string)",
                   description: "A self inserting character key",
                   action: modifyAction.thunk,
                   inverseAction: modifyAction.inverse)
  }

  @discardableResult
  func modify(_ textContentStorage: NSTextContentStorage, in ranges: [NSRange], with string: NSAttributedString) throws -> (thunk: (() -> Void), inverse: (() -> Void)) {
    let previousContentInRanges = ranges.compactMap { range -> (range: NSRange, attributedSubstring: NSAttributedString)? in
      guard let textStorage = textContentStorage.textStorage else { return nil }
      return (range: range, attributedSubstring: textStorage.attributedSubstring(from: range))
    }

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

  func makeChangeSelectionCommand(_ selectionChange: TextSelectionChange) -> Command {
    return Command(lastExecuted: Date(),
                   name: "change-text-selection",
                   description: "Change the currently selected text") {
      print("Should select new ranges: \(selectionChange.to)")
    } inverseAction: {
      print("Revert selection to ranges: \(selectionChange.from)")
    }
  }
}
