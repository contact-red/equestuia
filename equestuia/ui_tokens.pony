use "collections"

primitive TokWord
primitive TokPackStart
primitive TokPackEnd
primitive TokAdd
primitive TokQuotedString
primitive TokId
primitive TokKeyValue
primitive TokSize
primitive TokMode

class val Token
  """
  A single parsed token from a DSL line.
  """
  let kind: (TokWord | TokPackStart | TokPackEnd | TokAdd
    | TokQuotedString | TokId | TokKeyValue | TokSize | TokMode)
  let value: String val
  let key: String val

  new val create(
    kind': (TokWord | TokPackStart | TokPackEnd | TokAdd
      | TokQuotedString | TokId | TokKeyValue | TokSize | TokMode),
    value': String val,
    key': String val = "")
  =>
    kind = kind'
    value = value'
    key = key'

class val ParsedLine
  """
  A tokenized line with its indentation level.
  """
  let indent: USize
  let tokens: Array[Token] val

  new val create(indent': USize, tokens': Array[Token] val) =>
    indent = indent'
    tokens = tokens'

class val BuilderError
  """
  Error from parsing or building, with line number and message.
  """
  let line: USize
  let message: String val

  new val create(line': USize, message': String val) =>
    line = line'
    message = message'

  fun string(): String val =>
    "Line " + line.string() + ": " + message
