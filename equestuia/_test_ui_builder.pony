use "pony_test"

// Mock output that discards writes — avoids stdin subscription keeping runtime alive
actor _MockOutput is TerminalOutput
  be write(data: Array[U8] val) => None

// Mock input that does nothing — avoids subscribing to real stdin
actor _MockInput is TerminalInput
  be subscribe(listener: InputListener tag) => None
  be dispose() => None

class \nodoc\ iso _TestBuilderSimpleLabel is UnitTest
  fun name(): String => "UIBuilder.simple_label"

  fun apply(h: TestHelper) =>
    let output = _MockOutput
    let input = _MockInput
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
    let output = _MockOutput
    let input = _MockInput
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
    let output = _MockOutput
    let input = _MockInput
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
    let output = _MockOutput
    let input = _MockInput
    (let tw, let th) = TermSize()
    let compositor = Compositor(output, tw, th)
    let input_actor = InputActor(input, compositor)

    let builder = UIBuilder(compositor, input_actor)
    match builder.build(
      "// This is a comment\nvbox // root\n  pack-start *x1\n    label \"Hello\"")
    | let _: Widget tag => None
    | let e: BuilderError => h.fail(e.string())
    end

class \nodoc\ iso _TestBuilderStack is UnitTest
  fun name(): String => "UIBuilder.stack"

  fun apply(h: TestHelper) =>
    let output = _MockOutput
    let input = _MockInput
    (let tw, let th) = TermSize()
    let compositor = Compositor(output, tw, th)
    let input_actor = InputActor(input, compositor)
    let builder = UIBuilder(compositor, input_actor)
    match builder.build(
      "stack #mystack\n  add \"page1\"\n    label \"Page One\"\n  add \"page2\"\n    label \"Page Two\"")
    | let _: Widget tag => None
    | let e: BuilderError => h.fail(e.string())
    end
    match builder.get_widget("mystack")
    | let _: Widget tag => None
    | None => h.fail("widget #mystack not found")
    end
    match builder.get_widget("page1")
    | let _: Widget tag => None
    | None => h.fail("widget page1 not found")
    end
    match builder.get_widget("page2")
    | let _: Widget tag => None
    | None => h.fail("widget page2 not found")
    end

class \nodoc\ iso _TestBuilderStandaloneTabBar is UnitTest
  fun name(): String => "UIBuilder.standalone_tabbar"

  fun apply(h: TestHelper) =>
    let output = _MockOutput
    let input = _MockInput
    (let tw, let th) = TermSize()
    let compositor = Compositor(output, tw, th)
    let input_actor = InputActor(input, compositor)
    let builder = UIBuilder(compositor, input_actor)
    match builder.build("tabbar #mytabs")
    | let _: Widget tag => None
    | let e: BuilderError => h.fail(e.string())
    end
    match builder.get_widget("mytabs")
    | let _: Widget tag => None
    | None => h.fail("widget #mytabs not found")
    end
