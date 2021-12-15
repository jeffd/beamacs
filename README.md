# BeaMACS

 BeaMACS is a toy text editor for macOS, written with some minimal SwiftUI and setup to use NSTextView with TextKit 2, which was released in 2021.

The overall design is attempting to recreate an EMACS like setup with modes, shortcuts, and commands.

To get something that is user interactive, there are some modifications to NSTextView that intercepts `keyDown:` and forwards this and selection range changes to the `CommandReader`. Regular macOS commands will fail, only shortcuts that are defined in BeaMACS will work.

## CommandReader

The `CommandReader` dispatches on incoming keyboard shortcuts, looking up commands in the current mode that are mapped to keystrokes.

It also handles Undo and Redo. Commands are grouped by time, so commands run in successive order can be undone in one setup, instead of say one letter at a time. This happens in `undoNextGroup` and `redoNextGroup`.

All mutating commands have an inverse function that keep track of what is needed to revert its change.

## Fundamental Mode

This is the base mode for editing text. It has some basic text editing support. Alphanumeric keys that do not have any modifier keys are assumed to be self inserting, so they will insert themselves into the file at the current selection range.

## Demo Video

https://user-images.githubusercontent.com/2890/146105212-d75793a3-4e5e-4331-b416-9692ae58ab79.mp4

