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

#if os(macOS)
struct BufferView: NSViewRepresentable {
  let editorView = EditorView()

  func makeNSView(context: Context) -> some NSView {
    editorView
  }

  func updateNSView(_ nsView: NSViewType, context: Context) {

  }
}

internal class BMTextView: NSTextView {
  override var acceptsFirstResponder: Bool {
    true
  }
}

internal class EditorView: NSView, NSTextViewDelegate {
  private let textLayoutManager = NSTextLayoutManager()
  private var textContentStorage = NSTextContentStorage()
  private let textContainer: NSTextContainer
  private let textView: BMTextView
  private let scrollView = NSScrollView()

  override init(frame frameRect: NSRect) {
    textContainer = .init(size: frameRect.size)
    textLayoutManager.textContainer = textContainer
    textView = .init(frame: frameRect, textContainer: textContainer)
    super.init(frame: frameRect)
    doInit()
  }

  required init?(coder: NSCoder) {
    textContainer = .init(coder: coder)
    textLayoutManager.textContainer = textContainer
    textView = .init(frame: .zero, textContainer: textContainer)
    super.init(coder: coder)
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
//    textView.minSize = .init()
//    textView.maxSize = containerSize
    textView.isVerticallyResizable = true
    textView.isHorizontallyResizable = true
    textContentStorage.performEditingTransaction {
      textView.textStorage?.append(NSAttributedString(string: "Text content..."))
    }
    scrollView.documentView = textView
  }

  override var acceptsFirstResponder: Bool {
    true
  }

  override func keyDown(with event: NSEvent) {
    print("\(event.keyCode)")
    // Note: For simplicity we'll ignore things like chorded input
    if let firstKeyChar: Character = event.charactersIgnoringModifiers?.first {
      let key = KeyEquivalent(firstKeyChar)
      // TODO: Figure out modifiers
      let shortcut = KeyboardShortcut(key, modifiers: .init(rawValue: Int(event.modifierFlags.rawValue)), localization: .automatic)

      print("Shortcut: \(shortcut)")

      textContentStorage.performEditingTransaction {
        textView.textStorage?.append(NSAttributedString(string: event.charactersIgnoringModifiers ?? ""))
      }
    }
    else {
      super.keyDown(with: event)
    }
  }

  func insertText() {
    textContentStorage.performEditingTransaction {
      textView.textStorage?.append(NSAttributedString(string: "Text content..."))
    }
  }

  func textView(_ textView: NSTextView, shouldChangeTextInRanges affectedRanges: [NSValue], replacementStrings: [String]?) -> Bool {
    print("shouldChangeTextInRanges: \(affectedRanges)")
    return true
  }

  func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
    print("shouldChangeTextInRanges: \(affectedCharRange)")
    return true
  }

  func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    print("doCommandBy: \(commandSelector)")
    return true
  }

  func textView(_ textView: NSTextView, candidates: [NSTextCheckingResult], forSelectedRange selectedRange: NSRange) -> [NSTextCheckingResult] {
    print("candidates: \(candidates) forSelectedRange: \(selectedRange)")
    return candidates
  }

  func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRanges oldSelectedCharRanges: [NSValue], toCharacterRanges newSelectedCharRanges: [NSValue]) -> [NSValue] {
    print("willChangeSelectionFromCharacterRanges: \(oldSelectedCharRanges) toCharacterRanges: \(newSelectedCharRanges)")
    return newSelectedCharRanges
  }
}
#endif

struct SwiftUIView_Previews: PreviewProvider {
  static var previews: some View {
    BufferView()
  }
}
