//
//  Tests_macOS.swift
//  Tests macOS
//
//  Created by Jeff Dlouhy on 12/10/21.
//

import XCTest
import SwiftUI
import beamacs

class Tests_macOS: XCTestCase {
  var testDocument = beamacsDocument()
  var commandReader = CommandReader()

  override func setUpWithError() throws {
    testDocument.textContentStorage.textStorage = .init(string: "")
    commandReader = CommandReader()
    commandReader.currentMode.currentDocument = testDocument
    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testUndoRedo() throws {
    // UI tests must launch the application that they test.
    let app = XCUIApplication()
    app.launch()

    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.

    let textView = XCUIApplication().windows["Untitled"].scrollViews.children(matching: .textView).element
    textView.click()
    textView.typeText("beamacs")
    sleep(3)
    textView.typeText("rocks")
    textView.typeKey("z", modifierFlags:[.command])
    textView.typeKey("r", modifierFlags:[.command])
  }

  func testInsert() throws {
    // Note: NSTextView automatically moves the cursor when the backing store changes
    // so we do not manually move it, but do receive the updated events in the running app.
    try commandReader.dispatchOnShortcut(KeyboardShortcut("h"))
    // Manually update the selection for the purpose of testing
    commandReader.currentMode.currentSelections = [NSRange(location: 1, length: 0)]
    try commandReader.dispatchOnShortcut(KeyboardShortcut("e"))
    commandReader.currentMode.currentSelections = [NSRange(location: 2, length: 0)]
    try commandReader.dispatchOnShortcut(KeyboardShortcut("l"))
    commandReader.currentMode.currentSelections = [NSRange(location: 3, length: 0)]
    try commandReader.dispatchOnShortcut(KeyboardShortcut("l"))
    commandReader.currentMode.currentSelections = [NSRange(location: 4, length: 0)]
    try commandReader.dispatchOnShortcut(KeyboardShortcut("o"))
    commandReader.currentMode.currentSelections = [NSRange(location: 5, length: 0)]

    // Insert 'hello' one letter at a time
    XCTAssertEqual(testDocument.textContentStorage.textStorage?.string, NSTextStorage(string: "hello").string)

    // Delete one letter
    try commandReader.dispatchOnShortcut(KeyboardShortcut(.delete))
    XCTAssertEqual(testDocument.textContentStorage.textStorage?.string, NSTextStorage(string: "hell").string)
  }
}
