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

    let vbox = VBox(compositor, term_w, term_h)
    let viewport = ViewPort(NorthWest, term_w, term_h)
    compositor.register(vbox, viewport)
    input_actor.register_widget(vbox)

    // Top label
    let top_label = Label(vbox, term_w, 1, "Keyboard Tester!", BrightGreen)
    vbox.add_child(top_label, SizeHint(term_w, 1), PackOption)
    top_label.trigger_render()

    // Frame around the keyboard
    let frame0: Frame = Frame(vbox, term_w / 2, 4, "Frame 0", Red)
    vbox.add_child(frame0, SizeHint(term_w / 2, 4), PackOption(where expand' = true, fill' = true))

    let keyb: Keyboard = Keyboard(frame0, input)
    input_actor.register_focusable(keyb)
    frame0.set_child(keyb)

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
  let _parent: WidgetParent tag
  var _width: USize = 80
  var _height: USize = 24
  var _focused: Bool = false
  let _input: TerminalInput tag
  let _child_grids: Array[(Any tag, Grid)]

  new create(
    p: WidgetParent tag,
    input: TerminalInput tag)
  =>
    _parent = p
    _input = input
    _child_grids = Array[(Any tag, Grid)]

  // -- Widget + CompositeWidget required helpers --

  fun ref parent(): WidgetParent tag => _parent
  fun ref width(): USize => _width
  fun ref height(): USize => _height
  fun ref set_size(w: USize, h: USize) => _width = w; _height = h
  fun ref child_grids(): Array[(Any tag, Grid)] => _child_grids

  fun ref render_background(): Grid =>
    Grid.filled(_width, _height, Cell.empty())

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


