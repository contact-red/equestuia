trait tag TerminalOutput
  """
  Abstraction for terminal output. Users can substitute network sockets,
  test harnesses, etc.
  """
  be write(data: Array[U8] val)
    """
    Write bytes to the output.
    """

trait tag TerminalInput
  """
  Abstraction for terminal input. Forwards raw bytes to a listener.
  """
  be subscribe(listener: InputListener tag)
    """
    Begin forwarding input bytes to the given listener.
    """
  be dispose()
    """
    Stop reading input and release resources.
    """

trait tag InputListener
  """Internal trait for receiving raw bytes from a TerminalInput."""
  be receive(data: Array[U8] val)

actor StdoutOutput is TerminalOutput
  """
  Default TerminalOutput that writes to an OutStream (typically env.out).
  """
  let _out: OutStream

  new create(out: OutStream) =>
    """
    Create a StdoutOutput wrapping the given OutStream.
    """
    _out = out

  be write(data: Array[U8] val) =>
    """
    Write bytes to the underlying OutStream.
    """
    _out.write(data)

actor StdinInput is TerminalInput
  """
  Default TerminalInput that reads from stdin via Pony's InputNotify.
  """
  var _listener: (InputListener tag | None) = None
  let _env: Env

  new create(env: Env) =>
    """
    Create a StdinInput bound to the given Env.
    """
    _env = env

  be subscribe(listener: InputListener tag) =>
    """
    Subscribe a listener to receive raw bytes from stdin.
    """
    _listener = listener
    _env.input(
      object iso is InputNotify
        let _l: InputListener tag = listener

        fun ref apply(data: Array[U8] iso) =>
          _l.receive(consume data)

        fun ref dispose() =>
          None
      end,
      512)

  be dispose() =>
    """
    Stop reading input. Passing None unsubscribes the ASIO event on stdin,
    allowing the runtime to shut down once no actors have pending work.
    """
    _listener = None
    _env.input(None, 0)
