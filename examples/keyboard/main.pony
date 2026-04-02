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

    /* Design:
     *
     * |VBox ------------------------------------------|
     * | Label "Keyboard Tester"                       |
     * || Frame -------------------------------------||
     * ||| VBox --------------------------------------|||
     *     Keyb stuff here
     *
     * Text box here
     */

    let vbox = VBox(compositor)
    let viewport = ViewPort(NorthWest, term_w, term_h)
    compositor.register(vbox, viewport)
    input_actor.register_widget(vbox)

    // Top label
    let top_label = Label(vbox, "Keyboard Tester!", BrightGreen)
    vbox.pack_start(top_label, term_w, 1)

    // Frame around the keyboard
    let hbox: HBox = HBox(vbox)
//    let b0: Label = Label(hbox,0,0,"")
//    let b1: Label = Label(hbox,0,0,"")
//    vbox.add_child(b0, SizeHint(1,1), PackOption(where expand' = true, fill' = true))
    vbox.pack_start(hbox, 100, 20)
//    vbox.add_child(b1, SizeHint(1,1), PackOption(where expand' = true, fill' = true))

    let keyb: Keyboard = Keyboard(hbox, input)
    hbox.pack_start(keyb, 100, 20)
    input_actor.register_focusable(keyb)

    // Kick off the layout cascade — must be after all children are added
    vbox.resize(term_w, term_h)

/*
  fun build_row(keyb_vbox: VBox): HBox =>
    let rowbox: HBox = HBox(keyb_vbox, 10, 10)
    let f0: Frame = Frame(rowbox, 10, 10, "wibble")
    let l0: Label = Label(f0, 1, 1, "X")
    f0.set_child(l0)
    rowbox.add_child(f0, SizeHint(10, 10), PackOption)
    rowbox
*/


/*
    let hline0 = HLine(vbox, 10)
    let hline1 = HLine(vbox, 10)
    vbox.add_child(hline0, SizeHint(term_w, 1), PackOption)

    let hbox = HBox(vbox, term_w, 4)
    vbox.add_child(hbox, SizeHint(term_w, 4), PackOption(where expand' = true, fill' = true))

    // Counter Frame 0
    let frame0: Frame = Frame(hbox, term_w / 2, 4, "Frame 0", Red)
    hbox.add_child(frame0, SizeHint(term_w / 2, 4), PackOption(where expand' = true, fill' = true))

    // Counter inside the frame 0
    let counter0 = Counter(frame0, term_w, 7, env, input)
    frame0.set_child(counter0)
    input_actor.register_focusable(counter0)
    counter0.trigger_render()

    // Counter Frame 1
    let frame1: Frame = Frame(hbox, term_w / 2, 4, "Frame 1", Red)
    hbox.add_child(frame1, SizeHint(term_w / 2, 4), PackOption(where expand' = true, fill' = true))

    // Counter inside the frame 1
    let counter1 = Counter(frame1, term_w, 7, env, input)
    frame1.set_child(counter1)
    input_actor.register_focusable(counter1)
    counter1.trigger_render()

    // Bottom label
    vbox.add_child(hline1, SizeHint(term_w, 1), PackOption)
    let bottom_label = Label(vbox, term_w, 1, "Bottom of VBox", Red)
    vbox.add_child(bottom_label, SizeHint(term_w, 1), PackOption(where from_end' = true))
    bottom_label.trigger_render()
*/




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

    render_row([ "`"; "1"; "2"; "3"; "4"; "5"; "6"; "7"; "8"; "9"; "0"; "-"; "+"; "Bksp"], rows)
    render_row([ "Tab"; "Q"; "W"; "E"; "R"; "T"; "Y"; "U"; "I"; "O"; "P"; "["; "]"; "\\"], rows)
    render_row([ "Caps"; "A"; "S"; "D"; "F"; "G"; "H"; "J"; "K"; "L"; ";"; "'"; "Enter"], rows)
    render_row([ "Shift"; "Z"; "X"; "C"; "V"; "B"; "N"; "M"; ","; "."; "/"; "Shift"], rows)
    render_row([ "Ctrl"; "Win"; "Alt"; "Space"; "Alt"; "Fn"; "Menu"; "Ctrl"], rows)



  fun ref render_row(kys: Array[String], rows: VBox) =>
    let row1 = HBox(rows)
//    let b0: Label = Label(row1, 0, 0, "")
//    row1.add_child(b0, SizeHint(0, 0), PackOption(where expand' = true,  fill' = true))
    for r in kys.values() do
      let f: Frame = Frame(row1)
      let l: Label = Label(f, r)
      mapping.insert(r, l)
      f.set_child(l)
      row1.pack_start(f, r.size()+2, 3)
    end
//    let b1: Label = Label(row1, 0, 0, "")
//    row1.add_child(b1, SizeHint(0, 0), PackOption(where expand' = true,  fill' = true))
    rows.pack_start(row1, 100, 3)

  // -- Widget + CompositeWidget required helpers --

  fun ref state(): WidgetState => _state

  fun ref render_background(): Grid =>
    Grid.filled(_state.width, _state.height, Cell.empty())

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
