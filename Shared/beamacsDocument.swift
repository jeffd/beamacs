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

enum FileError: Error {
  case noString
}

// MARK: - beamacsDocument

struct beamacsDocument: FileDocument {
  // MARK: Lifecycle

  init(text: String = "Hello, world!") {
    self.textContentStorage = .init()
    self.textContentStorage.performEditingTransaction {
      self.textContentStorage.textStorage?.append(.init(string: text))
    }
  }

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }

    self.textContentStorage = .init()

    do {
      try textContentStorage.textStorage?.read(from: data, options: .init(), documentAttributes: nil, error: ())
    } catch {
      print("unable to read file content")
      __NSBeep()
      throw CocoaError(.fileReadCorruptFile)
    }
  }

  // MARK: Internal

  static var readableContentTypes: [UTType] { [.exampleText] }

  var textContentStorage: NSTextContentStorage

  func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
    guard let attributedDocumentString = textContentStorage.attributedString else { throw FileError.noString }

    let data = try attributedDocumentString.data(from: .init(location: 0,
                                                             length: attributedDocumentString.length),
                                                 documentAttributes: [.documentType : NSAttributedString.DocumentType.rtf])

    return .init(regularFileWithContents: data)
  }
}
