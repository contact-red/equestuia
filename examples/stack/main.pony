use "../../equestuia"
use "collections"
use "signals"

actor QuitHandler is Widget
  """
  Invisible widget that listens for 'q' to quit.
  """
  let _state: WidgetState
  let _input: TerminalInput tag
  let _env: Env

  new create(p: WidgetParent tag, env: Env, input: TerminalInput tag) =>
    _state = WidgetState(p)
    _env = env
    _input = input

  fun ref state(): WidgetState => _state

  fun ref render(): Grid =>
    Grid.filled(_state.width, _state.height, _state.empty_cell())

  be receive_key(key: KeyEvent) =>
    match key.key
    | CharKey =>
      if key.char == 'q' then
        _env.out.write(AnsiEncoder.clear_screen())
        _env.out.write(AnsiEncoder.move_to(0, 0))
        _env.out.write(AnsiEncoder.reset())
        _env.out.write(AnsiEncoder.show_cursor())
        _input.dispose()
      end
    end

actor Main
  new create(env: Env) =>
    let output = StdoutOutput(env.out)
    let input = StdinInput(env)

    (let term_w, let term_h) = TermSize()
    let compositor = Compositor(output, term_w, term_h)
    let input_actor = InputActor(SignalAuth(env.root), input, compositor)

    let builder = UIBuilder(compositor, input_actor)
    builder.register("quit", {(p: WidgetParent tag): Widget tag =>
      QuitHandler(p, env, input)
    } val)

    match builder.build(
"""
vbox
  pack-start *x1
    label "Stack Demo  (Tab = switch focus, Enter/Space = select tab, q = quit)" fg=cyan
  pack-start *x1
    hline
  pack-start *x0 fill
    stack #pages tabs=north
      add "home" tab="Home"
        vbox
          pack-start *x1
            label "Welcome to equesTUIa!" fg=green align=center
          pack-start *x1
            label ""
          pack-start *x1
            label "This demo shows a Stack widget with tabbed navigation." align=center
          pack-start *x1
            label "Use Tab to focus the tab bar, then arrow keys + Enter." align=center
      add "colors" tab="Colors"
        vbox
          pack-start *x1
            label "Red" fg=red
          pack-start *x1
            label "Green" fg=green
          pack-start *x1
            label "Blue" fg=blue
          pack-start *x1
            label "Yellow" fg=yellow
          pack-start *x1
            label "Cyan" fg=cyan
          pack-start *x1
            label "Magenta" fg=magenta
      add "layout" tab="Layout"
        hbox
          pack-start 20x0 fill
            frame "Left"
              label "Panel A" fg=yellow align=center
          pack-start 20x0 fill
            frame "Center"
              label "Panel B" fg=cyan align=center
          pack-start 20x0 fill
            frame "Right"
              label "Panel C" fg=green align=center
  pack-start *x1
    hline
  pack-end *x1
    quit focusable
"""
    )
    | let root: Widget tag =>
      compositor.register_root(root)
      root.resize(term_w, term_h)
    | let e: BuilderError =>
      env.out.print("Builder error: " + e.string())
    end
