//
//  SwiftUIView.swift
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

import SwiftUI
import Combine

#if os(macOS)
struct BufferView: NSViewRepresentable {
  private let editorView: EditorView

  init(_ textContentStorage: NSTextContentStorage, commandReader: CommandReader) {
    self.editorView = EditorView(textContentStorage: textContentStorage, commandReader: commandReader)
  }

  func makeNSView(context: Context) -> some NSView {
    editorView
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {}
}

/// For demonstration purposes, we'll forward events up one level.
/// However, we'll accept first responder so we get focused text selection.
internal class BMTextView: NSTextView {
  override var acceptsFirstResponder: Bool {
    true
  }

  override func keyDown(with event: NSEvent) {
    superview?.keyDown(with: event)
  }
}

internal class EditorView: NSView, NSTextViewDelegate {
  private let textLayoutManager = NSTextLayoutManager()
  private var textContentStorage: NSTextContentStorage
  private let textContainer: NSTextContainer
  private let textView: BMTextView
  private let scrollView = NSScrollView()
  private var commandReader: CommandReader?

  override init(frame frameRect: NSRect) {
    textContainer = .init(size: frameRect.size)
    textLayoutManager.textContainer = textContainer
    textContentStorage = .init()
    textView = .init(frame: frameRect, textContainer: textContainer)
    super.init(frame: frameRect)
    doInit()
  }

  required init?(coder: NSCoder) {
    textContainer = .init(coder: coder)
    textLayoutManager.textContainer = textContainer
    textContentStorage = .init()
    textView = .init(frame: .zero, textContainer: textContainer)
    super.init(coder: coder)
    doInit()
  }

  init(textContentStorage: NSTextContentStorage, commandReader: CommandReader) {
    self.textContentStorage = textContentStorage
    textContainer = .init()
    textLayoutManager.textContainer = textContainer
    textView = .init(frame: .zero, textContainer: textContainer)
    super.init(frame: .zero)
    self.commandReader = commandReader
    doInit()
  }

  private func doInit() {
    setupScrollView()
    setupTextView()
  }

  private func setupScrollView() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(scrollView)

    NSLayoutConstraint.activate([
      scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])

    scrollView.borderType = .noBorder
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = false
  }

  private func setupTextView() {
    textContentStorage.addTextLayoutManager(textLayoutManager)

    let containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
    textContainer.containerSize = containerSize
    textContainer.widthTracksTextView = true

    textView.delegate = self
    textView.isEditable = true
    textView.isSelectable = true
    textView.isVerticallyResizable = true
    textView.isHorizontallyResizable = true
    textView.usesAdaptiveColorMappingForDarkAppearance = true
    scrollView.documentView = textView
  }

  override var acceptsFirstResponder: Bool {
    true
  }

  /// Note: This is just a quick and dirty way to send the events to the
  /// CommandReader from outside the usual NSResponder chain.
  override func keyDown(with event: NSEvent) {
    if let shortcut = KeyboardShortcut(event: event) {
      commandReader?.latestKeyDown.send(shortcut)
    } else {
      super.keyDown(with: event)
    }
  }

  ///
  /// Note:
  /// For purposes of demonstration, we'll prevent any outside changes to NSTextView from the system.
  ///
  func textView(_ textView: NSTextView, shouldChangeTextInRanges affectedRanges: [NSValue], replacementStrings: [String]?) -> Bool {
    return false
  }

  func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
    return false
  }

  func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    return true
  }

  func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRanges oldSelectedCharRanges: [NSValue], toCharacterRanges newSelectedCharRanges: [NSValue]) -> [NSValue] {
    /// Note: TextKit 2 has NSTextSelection objects which are nicer, however I cannot seem to find documentation on how to get
    /// their changes from the layout manager.
    let fromRanges = oldSelectedCharRanges.map(\.rangeValue)
    let toRanges = newSelectedCharRanges.map(\.rangeValue)

    // For possibly monitoring and allowing the undoing of selection, send these changes to the CommandReader.
    let rangeChange = TextSelectionChange(from: fromRanges, to: toRanges)
    commandReader?.latestSelection.send(rangeChange)

    return newSelectedCharRanges
  }
}
#endif

#if DEBUG
struct SwiftUIView_Previews: PreviewProvider {
  static var previews: some View {
    BufferView(.init(), commandReader: .init())
  }
}
#endif
