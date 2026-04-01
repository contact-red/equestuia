trait tag TerminalOutput
  """Abstraction for terminal output. Users can substitute network sockets, test harnesses, etc."""
  be write(data: Array[U8] val)

trait tag TerminalInput
  """Abstraction for terminal input. Forwards raw bytes to a listener."""
  be subscribe(listener: _InputListener tag)

trait tag _InputListener
  """Internal trait for receiving raw bytes from a TerminalInput."""
  be receive(data: Array[U8] val)

actor StdoutOutput is TerminalOutput
  let _out: OutStream

  new create(out: OutStream) =>
    _out = out

  be write(data: Array[U8] val) =>
    _out.write(data)

actor StdinInput is TerminalInput
  var _listener: (_InputListener tag | None) = None
  let _env: Env

  new create(env: Env) =>
    _env = env

  be subscribe(listener: _InputListener tag) =>
    _listener = listener
    _env.input(
      object iso is InputNotify
        let _l: _InputListener tag = listener

        fun ref apply(data: Array[U8] iso) =>
          _l.receive(consume data)

        fun ref dispose() =>
          None
      end,
      512)
