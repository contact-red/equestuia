use @ioctl[I32](fd: I32, cmd: ULong, ...) if posix

struct _WinSize
  """
  Matches the POSIX struct winsize layout for ioctl TIOCGWINSZ.
  """
  var row: U16 = 0
  var col: U16 = 0
  var xpixel: U16 = 0
  var ypixel: U16 = 0

primitive _TIOCGWINSZ
  """
  Platform-specific ioctl command number for TIOCGWINSZ.
  """
  fun apply(): ULong =>
    ifdef linux then
      21523
    elseif osx or bsd then
      1074295912
    else
      0
    end

primitive TermSize
  """
  Query the terminal dimensions via ioctl. Returns (cols, rows) or (80, 24)
  as a fallback if the query fails.
  """
  fun apply(): (USize, USize) =>
    """
    Return the current terminal size as (width, height).
    """
    let ws = _WinSize
    ifdef posix then
      let result = @ioctl(1, _TIOCGWINSZ(), ws)
      if (result == 0) and (ws.col > 0) and (ws.row > 0) then
        (ws.col.usize(), ws.row.usize())
      else
        (80, 24)
      end
    else
      (80, 24)
    end
