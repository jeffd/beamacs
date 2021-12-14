//
//  KeyboardShortcut+Extensions.swift
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

import SwiftUI

extension KeyboardShortcut {
  init?(event: NSEvent) {
    // Note: For simplicity we'll ignore things like chorded input and just get the first character.
    guard let firstKeyChar: Character = event.charactersIgnoringModifiers?.first else { return nil }
    self.init(KeyEquivalent(firstKeyChar), modifiers: Self.convert(modifierFlags: event.modifierFlags), localization: .automatic)
  }

  /// A quick and dirty mapping of events
  static let modifierMapping: [NSEvent.ModifierFlags.RawValue : EventModifiers] = [
    NSEvent.ModifierFlags.capsLock.rawValue : .capsLock,
    NSEvent.ModifierFlags.command.rawValue : .command,
    NSEvent.ModifierFlags.control.rawValue : .control,
    NSEvent.ModifierFlags.numericPad.rawValue : .numericPad,
    NSEvent.ModifierFlags.option.rawValue : .option,
    NSEvent.ModifierFlags.shift.rawValue : .shift
  ]

  /// Convert NSEvent.ModifierFlags to the new EventModifiers
  ///
  /// Note: This is a quick and dirty way to convert between the two different masks
  ///       since the raw values are different.
  ///
  /// - Parameter modifierFlags: NSEvent.ModifierFlags
  /// - Returns: EventModifers with their equivalents when possible
  private static func convert(modifierFlags: NSEvent.ModifierFlags) -> EventModifiers {
    var convertedEvents: EventModifiers = .init()
    // If any of the old events in the option set are mappable to new ones, add them to the convertedEvents
    Self.modifierMapping.forEach { (key: NSEvent.ModifierFlags.RawValue, value: EventModifiers) in
      let eventFlag = NSEvent.ModifierFlags(rawValue: key)
      if modifierFlags.contains(eventFlag) {
        convertedEvents.insert(value)
      }
    }

    return convertedEvents
  }
}
