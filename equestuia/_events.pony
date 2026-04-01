primitive CharKey
primitive Enter
primitive Escape
primitive Tab
primitive Backspace
primitive Up
primitive Down
primitive Left
primitive Right
primitive Home
primitive End
primitive PageUp
primitive PageDown
primitive Insert
primitive Delete
primitive F1
primitive F2
primitive F3
primitive F4
primitive F5
primitive F6
primitive F7
primitive F8
primitive F9
primitive F10
primitive F11
primitive F12

type Key is
  ( CharKey | Enter | Escape | Tab | Backspace
  | Up | Down | Left | Right | Home | End
  | PageUp | PageDown | Insert | Delete
  | F1 | F2 | F3 | F4 | F5 | F6
  | F7 | F8 | F9 | F10 | F11 | F12 )

primitive Modifiers
  fun shift(): U8 => 0x01
  fun ctrl(): U8  => 0x02
  fun alt(): U8   => 0x04

class val KeyEvent
  let key: Key
  let char: U32
  let modifiers: U8

  new val create(key': Key, char': U32 = 0, modifiers': U8 = 0) =>
    key = key'
    char = char'
    modifiers = modifiers'

// Mouse action primitives

primitive Press
primitive Release
primitive Move
primitive ScrollUp
primitive ScrollDown

type MouseAction is (Press | Release | Move | ScrollUp | ScrollDown)

// Mouse button primitives

primitive LeftButton
primitive MiddleButton
primitive RightButton
primitive NoButton

type MouseButton is (LeftButton | MiddleButton | RightButton | NoButton)

class val MouseEvent
  let action: MouseAction
  let button: MouseButton
  let col: U16
  let row: U16
  let modifiers: U8

  new val create(
    action': MouseAction,
    button': MouseButton,
    col': U16,
    row': U16,
    modifiers': U8 = 0)
  =>
    action = action'
    button = button'
    col = col'
    row = row'
    modifiers = modifiers'

class val ResizeEvent
  let width: U16
  let height: U16

  new val create(width': U16, height': U16) =>
    width = width'
    height = height'

type InputEvent is (KeyEvent | MouseEvent | ResizeEvent)
