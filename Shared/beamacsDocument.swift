//
//  beamacsDocument.swift
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
import UniformTypeIdentifiers

extension UTType {
  static var exampleText: UTType {
    UTType(importedAs: "com.example.plain-text")
  }
}

// MARK: - beamacsDocument

struct beamacsDocument: FileDocument {
  // MARK: Lifecycle

  init(text: String = "Hello, world!") {
    self.text = text
  }

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents,
          let string = String(data: data, encoding: .utf8)
    else {
      throw CocoaError(.fileReadCorruptFile)
    }
    self.text = string
  }

  // MARK: Internal

  static var readableContentTypes: [UTType] { [.exampleText] }

  var text: String

  func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
    let data = text.data(using: .utf8)!
    return .init(regularFileWithContents: data)
  }
}
