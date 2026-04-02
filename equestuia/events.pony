primitive CharKey
  """
  A printable character key.
  """
primitive Enter
  """
  Enter / Return key.
  """
primitive Escape
  """
  Escape key.
  """
primitive Tab
  """
  Tab key.
  """
primitive Backspace
  """
  Backspace key.
  """
primitive Up
  """
  Up arrow key.
  """
primitive Down
  """
  Down arrow key.
  """
primitive Left
  """
  Left arrow key.
  """
primitive Right
  """
  Right arrow key.
  """
primitive Home
  """
  Home key.
  """
primitive End
  """
  End key.
  """
primitive PageUp
  """
  Page Up key.
  """
primitive PageDown
  """
  Page Down key.
  """
primitive Insert
  """
  Insert key.
  """
primitive Delete
  """
  Delete key.
  """
primitive F1
  """
  F1 function key.
  """
primitive F2
  """
  F2 function key.
  """
primitive F3
  """
  F3 function key.
  """
primitive F4
  """
  F4 function key.
  """
primitive F5
  """
  F5 function key.
  """
primitive F6
  """
  F6 function key.
  """
primitive F7
  """
  F7 function key.
  """
primitive F8
  """
  F8 function key.
  """
primitive F9
  """
  F9 function key.
  """
primitive F10
  """
  F10 function key.
  """
primitive F11
  """
  F11 function key.
  """
primitive F12
  """
  F12 function key.
  """

type Key is
  ( CharKey | Enter | Escape | Tab | Backspace
  | Up | Down | Left | Right | Home | End
  | PageUp | PageDown | Insert | Delete
  | F1 | F2 | F3 | F4 | F5 | F6
  | F7 | F8 | F9 | F10 | F11 | F12 )

primitive Modifiers
  """
  Bitfield constants for keyboard modifiers.
  """
  fun shift(): U8 =>
    """
    Shift modifier bit.
    """
    0x01
  fun ctrl(): U8 =>
    """
    Ctrl modifier bit.
    """
    0x02
  fun alt(): U8 =>
    """
    Alt modifier bit.
    """
    0x04

class val KeyEvent
  """
  A keyboard input event.
  """
  let key: Key
  let char: U32
  let modifiers: U8

  new val create(key': Key, char': U32 = 0, modifiers': U8 = 0) =>
    """
    Create a key event. For CharKey, char holds the Unicode codepoint.
    """
    key = key'
    char = char'
    modifiers = modifiers'

primitive Press
  """
  Mouse button pressed.
  """
primitive Release
  """
  Mouse button released.
  """
primitive Move
  """
  Mouse moved.
  """
primitive ScrollUp
  """
  Mouse scroll up.
  """
primitive ScrollDown
  """
  Mouse scroll down.
  """

type MouseAction is (Press | Release | Move | ScrollUp | ScrollDown)

primitive LeftButton
  """
  Left mouse button.
  """
primitive MiddleButton
  """
  Middle mouse button.
  """
primitive RightButton
  """
  Right mouse button.
  """
primitive NoButton
  """
  No mouse button (used for move events).
  """

type MouseButton is (LeftButton | MiddleButton | RightButton | NoButton)

class val MouseEvent
  """
  A mouse input event with position and button state.
  """
  let action: MouseAction
  let button: MouseButton
  let col: USize
  let row: USize
  let modifiers: U8

  new val create(
    action': MouseAction,
    button': MouseButton,
    col': USize,
    row': USize,
    modifiers': U8 = 0)
  =>
    """
    Create a mouse event at the given screen coordinates.
    """
    action = action'
    button = button'
    col = col'
    row = row'
    modifiers = modifiers'

class val ResizeEvent
  """
  Terminal resize event with new dimensions.
  """
  let width: USize
  let height: USize

  new val create(width': USize, height': USize) =>
    """
    Create a resize event with the new terminal dimensions.
    """
    width = width'
    height = height'

type InputEvent is (KeyEvent | MouseEvent | ResizeEvent)
