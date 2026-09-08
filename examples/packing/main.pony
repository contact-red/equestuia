use "../../equestuia"
use "collections"
use "signals"

actor Main
  new create(env: Env) =>
    let output = StdoutOutput(env.out)
    let input = StdinInput(env)

    (let term_w, let term_h) = TermSize()
    let compositor = Compositor(output, term_w, term_h)
    let input_actor = InputActor(SignalAuth(env.root), input, compositor)

    let builder = UIBuilder(compositor, input_actor)

    match builder.build(
"""
vbox focusable
  pack-start *x3
    hbox
      pack-start 21x3 fixed
        hbox
          pack-start 7x3 fixed
            frame 7x3
              label "fixed"
          pack-start 8x3 expand
            frame 7x3
              label "expand"
          pack-start 6x3 fill
            frame 6x3
              label "fill"
      pack-start 30x3 fill
        label " <-- Before Window is Expanded"
  pack-start *x3
    hbox align=center
      pack-start 7x3 fixed
        frame 7x3
          label "fixed"
      pack-start 7x3 fixed
        frame 7x3
          label "fixed"
      pack-start 7x3 fixed
        frame 7x3
          label "fixed"
  pack-start *x3
    hbox
      pack-start *x3 fill
        hbox
          pack-start 7x3 fixed
            frame 7x3
              label "fixed"
          pack-start 8x3 expand
            frame 7x3
              label "expand"
          pack-start 6x3 fill
            frame 6x3
              label "fill"
  pack-start *x3
    hbox
      pack-start *x3 fill
        hbox
          pack-start 7x3 fill
            frame 7x3
              label "fill left" align=start
          pack-start 8x3 fill
            frame 7x3
              label "fill center" align=center
          pack-start 6x3 fill
            frame 6x3
              label "fill right" align=end

"""
    )
    | let root: Widget tag =>
      compositor.register_root(root)
      root.resize(term_w, term_h)
    | let e: BuilderError =>
      env.out.print("Builder error: " + e.string())
    end

