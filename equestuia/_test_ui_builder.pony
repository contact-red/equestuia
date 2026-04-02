use "pony_test"

class \nodoc\ iso _TestBuilderSimpleLabel is UnitTest
  fun name(): String => "UIBuilder.simple_label"

  fun apply(h: TestHelper) =>
    let env = h.env
    let output = StdoutOutput(env.out)
    let input = StdinInput(env)
    (let tw, let th) = TermSize()
    let compositor = Compositor(output, tw, th)
    let input_actor = InputActor(input, compositor)

    let builder = UIBuilder(compositor, input_actor)
    match builder.build(
      "vbox\n  pack-start *x1\n    label #title \"Hello\" fg=green")
    | let _: Widget tag => None
    | let e: BuilderError => h.fail(e.string())
    end

    match builder.get_widget("title")
    | let _: Widget tag => None
    | None => h.fail("widget #title not found")
    end

class \nodoc\ iso _TestBuilderUnknownType is UnitTest
  fun name(): String => "UIBuilder.unknown_type"

  fun apply(h: TestHelper) =>
    let env = h.env
    let output = StdoutOutput(env.out)
    let input = StdinInput(env)
    (let tw, let th) = TermSize()
    let compositor = Compositor(output, tw, th)
    let input_actor = InputActor(input, compositor)

    let builder = UIBuilder(compositor, input_actor)
    match builder.build("bogus")
    | let _: Widget tag => h.fail("expected BuilderError for unknown type")
    | let e: BuilderError =>
      h.assert_true(
        e.string().contains("unknown widget type"),
        "error message should contain 'unknown widget type', got: " + e.string())
    end

class \nodoc\ iso _TestBuilderCustomWidget is UnitTest
  fun name(): String => "UIBuilder.custom_widget"

  fun apply(h: TestHelper) =>
    let env = h.env
    let output = StdoutOutput(env.out)
    let input = StdinInput(env)
    (let tw, let th) = TermSize()
    let compositor = Compositor(output, tw, th)
    let input_actor = InputActor(input, compositor)

    let builder = UIBuilder(compositor, input_actor)
    builder.register("custom",
      {(p: WidgetParent tag): Widget tag => Label(p)} val)
    match builder.build(
      "vbox\n  pack-start *x1\n    custom #mywidget")
    | let _: Widget tag => None
    | let e: BuilderError => h.fail(e.string())
    end

    match builder.get_widget("mywidget")
    | let _: Widget tag => None
    | None => h.fail("widget #mywidget not found")
    end

class \nodoc\ iso _TestBuilderComments is UnitTest
  fun name(): String => "UIBuilder.comments"

  fun apply(h: TestHelper) =>
    let env = h.env
    let output = StdoutOutput(env.out)
    let input = StdinInput(env)
    (let tw, let th) = TermSize()
    let compositor = Compositor(output, tw, th)
    let input_actor = InputActor(input, compositor)

    let builder = UIBuilder(compositor, input_actor)
    match builder.build(
      "// This is a comment\nvbox // root\n  pack-start *x1\n    label \"Hello\"")
    | let _: Widget tag => None
    | let e: BuilderError => h.fail(e.string())
    end
