use @pony_os_stderr[Pointer[U8]]()
use @fprintf[I32](stream: Pointer[U8] tag, fmt: Pointer[U8] tag, ...)
use @exit[None](status: I32)

primitive _Unreachable
  """
  Panic for code paths that should be impossible. Prints location and exits.
  """
  fun apply(loc: SourceLoc = __loc): None =>
    @fprintf(
      @pony_os_stderr(),
      "Unreachable code reached at %s:%s:%lu\n".cstring(),
      loc.file().cstring(),
      loc.method_name().cstring(),
      loc.line())
    @exit(1)
