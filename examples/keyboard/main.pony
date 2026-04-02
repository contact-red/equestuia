use "../../equestuia"
use "collections"

actor Main
  let keymap: Map[String, Label] = Map[String, Label]

  new create(env: Env) =>
    let output = StdoutOutput(env.out)
    let input = StdinInput(env)

    (let term_w, let term_h) = TermSize()
    let compositor = Compositor(output, term_w, term_h)
    let input_actor = InputActor(input, compositor)

    let vbox = VBox(compositor)
    vbox.set_debug_bg(Blue)
    input_actor.register_widget(vbox)

    // Top label
    let top_label = Label(vbox, "Keyboard Tester!", BrightGreen where align = AlignCenter)
    vbox.pack_start(top_label, 0, 1)

    // HBox around the keyboard, for alignment…
    let hbox: HBox = HBox(vbox, AlignCenter)
    hbox.set_debug_bg(Red)

    vbox.pack_start(hbox, 46, 15)

    let keyb: Keyboard = Keyboard(hbox, input)
    hbox.pack_start(keyb, 46, 15)
    input_actor.register_focusable(keyb)

    // Register root and kick off layout — must be after all children are added
    compositor.set_root(vbox)

actor Keyboard is CompositeWidget
  """
  Keyboard tester widget. Contains child widgets (e.g. VBox with rows
  of framed key labels) and composites them on top of its own background.
  Press 'q' to quit.
  """
  let _state: WidgetState
  var _focused: Bool = false
  let _input: TerminalInput tag

  var mapping: Map[String, Label] = Map[String, Label]

  new create(
    p: WidgetParent tag,
    input: TerminalInput tag)
  =>
    _state = WidgetState(p)
    _input = input

    let rows = VBox(this)
    register_child(rows)

    render_row([ "`"; "1"; "2"; "3"; "4"; "5"; "6"; "7"; "8"; "9"; "0"; "-"; "+"; " Bksp"], rows)
    render_row([ "Tab  "; "Q"; "W"; "E"; "R"; "T"; "Y"; "U"; "I"; "O"; "P"; "["; "]"; "\\"], rows)
    render_row([ "Caps"; "A"; "S"; "D"; "F"; "G"; "H"; "J"; "K"; "L"; ";"; "'"; "Enter"], rows)
    render_row([ "Shift "; "Z"; "X"; "C"; "V"; "B"; "N"; "M"; ","; "."; "/"; " Shift"], rows)
    render_row([ "Ctrl"; "Win"; "Alt"; " Space "; "Alt"; "Fn"; "Menu"; "Ctrl"], rows)



  fun ref render_row(kys: Array[String], rows: VBox) =>
    let row1 = HBox(rows, AlignCenter)
    for r in kys.values() do
      let f: Frame = Frame(row1)
      let l: Label = Label(f, r)
      mapping.insert(r, l)
      f.set_child(l)
      row1.pack_start(f, r.size()+2, 3)
    end
    rows.pack_start(row1, 100, 3)

  // -- Widget + CompositeWidget required helpers --

  fun ref state(): WidgetState => _state

  // -- Override behaviors --

  be receive_key(key: KeyEvent) =>
    match key.key
    | CharKey =>
      if key.char == 'q' then
        _input.dispose()
      end
    end

  be receive_focus() =>
    _focused = true
    render_and_send()

  be receive_blur() =>
    _focused = false
    render_and_send()
