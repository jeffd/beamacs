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

class CommandReader: NSObject, ObservableObject {
  private static let maxCommandGroupingDelta: TimeInterval = 2

  let latestKeyDown: PassthroughSubject<KeyboardShortcut, Never> = .init()
  let latestSelection: PassthroughSubject<TextSelectionChange, Never> = .init()

  private var keyDownSubscriber: AnyCancellable?
  private var selectionSubscriber: AnyCancellable?

  private var undoStack: Deque<Command> = .init()
  private var redoStack: Deque<Command> = .init()

  var currentMode = FundamentalMode()

  override init() {
    super.init()
    keyDownSubscriber = latestKeyDown
      .receive(on: RunLoop.main)
      .sink(receiveValue: { shortcut in
        self.dispatchOnShortcut(shortcut)
      })

    selectionSubscriber = latestSelection
      .receive(on: RunLoop.main)
      .sink(receiveValue: { latestChange in
        self.currentMode.currentSelections = latestChange.to
        // TODO: Possibly keep track of changes to selection from the mouse
      })
    
    // For demo purposes we will bind keys for Undo/Redo to the current mode
    currentMode.defineShortcut(KeyboardShortcut("z", modifiers: .command, localization: .automatic)) {
      .init(name: "undo", description: "undoes the last command", lastExecuted: Date()) { [weak self] in
        do {
          try self?.undoNextGroup(with: Self.maxCommandGroupingDelta)
        } catch {
          print("nothing left to undo!")
          __NSBeep()
        }
      }
    }

    currentMode.defineShortcut(KeyboardShortcut("r", modifiers: .command, localization: .automatic)) {
      .init(name: "redo", description: "redoes the last command", lastExecuted: Date()) { [weak self] in
        do {
          try self?.redoNextGroup(with: Self.maxCommandGroupingDelta)
        } catch {
          print("nothing else to redo!")
          __NSBeep()
        }
      }
    }
  }

  func dispatchOnShortcut(_ shortcut: KeyboardShortcut) {
    do {
      pushCommand(try currentMode.command(for: shortcut))
    } catch {
      __NSBeep()
      print("Unable to run command: \(error.localizedDescription)")
    }
  }

  private func pushCommand(_ command: Command) {
    let isCommandReversible = (command.inverseAction != nil)
    if isCommandReversible {
      // Wipe the redo stack
      //
      // Note: If we wanted to do a tree of undos/redos, we could branch here instead.
      redoStack.removeAll()
    }

    // Run the command
    command.action()

    // Add it to the undo stack if it can be reversed
    if isCommandReversible {
      undoStack.prepend(command)
    }
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
      poppedUndoCommand.inverseAction?()
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
}
