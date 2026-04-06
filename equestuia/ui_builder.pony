use "collections"

type WidgetFactory is {(WidgetParent tag): Widget tag} val

class ref UIBuilder
  let _compositor: Compositor tag
  let _input_actor: InputActor tag
  let _registry: Map[String, WidgetFactory]
  let _widgets_by_id: Map[String, Widget tag]

  new create(compositor: Compositor tag, input_actor: InputActor tag) =>
    _compositor = compositor
    _input_actor = input_actor
    _registry = Map[String, WidgetFactory]
    _widgets_by_id = Map[String, Widget tag]
    _register_defaults()

  fun ref _register_defaults() =>
    _registry("vbox") = {(p: WidgetParent tag): Widget tag => VBox(p)} val
    _registry("hbox") = {(p: WidgetParent tag): Widget tag => HBox(p)} val
    _registry("frame") = {(p: WidgetParent tag): Widget tag => Frame(p)} val
    _registry("label") = {(p: WidgetParent tag): Widget tag => Label(p)} val
    _registry("textbox") = {(p: WidgetParent tag): Widget tag => TextBox(p)} val
    _registry("hline") = {(p: WidgetParent tag): Widget tag => HLine(p)} val
    _registry("vline") = {(p: WidgetParent tag): Widget tag => VLine(p)} val
    _registry("canvas") = {(p: WidgetParent tag): Widget tag => Canvas(p)} val
    _registry("stack") = {(p: WidgetParent tag): Widget tag => Stack(p)} val
    _registry("tabbar") = {(p: WidgetParent tag): Widget tag =>
      TabBar(p, {(s: String val) => None} val)
    } val

  fun ref register(type_name: String, factory: WidgetFactory) =>
    _registry(type_name) = factory

  fun get_widget(id: String): (Widget tag | None) =>
    try _widgets_by_id(id)? else None end

  fun ref build(dsl: String): (Widget tag | BuilderError) =>
    let stripped = _strip_block_comments(dsl)
    let lines: Array[String] val = stripped.split_by("\n")

    // Parse all lines
    let parsed: Array[(USize, ParsedLine)] = Array[(USize, ParsedLine)]
    var line_num: USize = 1
    for line in lines.values() do
      let cleaned = UIParser.strip_comments(line)
      match UIParser.tokenize_line(cleaned, line_num)
      | let pl: ParsedLine =>
        if pl.tokens.size() > 0 then
          parsed.push((line_num, pl))
        end
      | let err: BuilderError =>
        return err
      end
      line_num = line_num + 1
    end

    if parsed.size() == 0 then
      return BuilderError(0, "empty DSL: no widgets defined")
    end

    // Stack: (indent, widget, type_name)
    let stack: Array[(USize, Widget tag, String)] = Array[(USize, Widget tag, String)]

    // Pending pack context: (indent, is_pack_start, width, height, PackOption)
    var pending_pack: ((USize, Bool, USize, USize, PackOption) | None) = None

    // Pending add context: (indent, child_name, optional tab label)
    var pending_add: ((USize, String val, (String val | None)) | None) = None

    var root: (Widget tag | None) = None

    // Track stacks needing tab wrapping: (wrapper, stack, position, tab_entries)
    let stacks_needing_tabs:
      Array[((VBox tag | HBox tag), Stack tag, String val,
        Array[(String val, String val)])]
      = Array[((VBox tag | HBox tag), Stack tag, String val,
        Array[(String val, String val)])]

    for entry in parsed.values() do
      (let ln, let pl) = entry
      let indent = pl.indent
      let tokens = pl.tokens
      // Pop stack entries with indent >= current indent
      while stack.size() > 0 do
        try
          (let si, _, _) = stack(stack.size() - 1)?
          if si >= indent then
            stack.pop()?
          else
            break
          end
        else
          break
        end
      end

      // Look at first token
      let first_token = try tokens(0)? else continue end

      match first_token.kind
      | TokPackStart | TokPackEnd =>
        let is_start = match first_token.kind
        | TokPackStart => true
        else false
        end

        // Extract size and mode from remaining tokens
        var pack_w: USize = 0
        var pack_h: USize = 0
        var pack_mode: PackMode = PackFixed

        for ti in Range(1, tokens.size()) do
          try
            let tok = tokens(ti)?
            match tok.kind
            | TokSize =>
              match UIParser.parse_size(tok.value, ln)
              | (let pw: USize, let ph: USize) =>
                pack_w = pw
                pack_h = ph
              | let err: BuilderError =>
                return err
              end
            | TokMode =>
              match ModeLookup(tok.value)
              | let m: PackMode => pack_mode = m
              | None =>
                return BuilderError(ln, "unknown pack mode: " + tok.value)
              end
            end
          end
        end

        let pack_opt = PackOption(pack_mode)
        pending_pack = (indent, is_start, pack_w, pack_h, pack_opt)

      | TokAdd =>
        // Extract child name from remaining tokens
        var add_name: (String val | None) = None
        var add_tab: (String val | None) = None

        for ti in Range(1, tokens.size()) do
          try
            let tok = tokens(ti)?
            match tok.kind
            | TokQuotedString =>
              add_name = tok.value
            | TokKeyValue =>
              if tok.key == "tab" then
                add_tab = tok.value
              end
            end
          end
        end

        match add_name
        | let name: String val =>
          pending_add = (indent, name, add_tab)
        | None =>
          return BuilderError(ln, "add directive requires a quoted name")
        end

      | TokWord =>
        let type_name = first_token.value

        // Determine parent
        let parent: WidgetParent tag = if stack.size() > 0 then
          try
            (_, let pw, _) = stack(stack.size() - 1)?
            match pw
            | let wp: WidgetParent tag => wp
            else
              _compositor
            end
          else
            _compositor
          end
        else
          _compositor
        end

        // Look up factory
        let factory = try
          _registry(type_name)?
        else
          return BuilderError(ln, "unknown widget type: " + type_name)
        end

        // Pre-scan for tabs= on stack widgets to create wrapper first
        var tabs_position: (String val | None) = None
        if type_name == "stack" then
          for ti in Range(1, tokens.size()) do
            try
              let tok = tokens(ti)?
              if (tok.kind is TokKeyValue) and (tok.key == "tabs") then
                match tok.value
                | "north" | "south" | "east" | "west" =>
                  tabs_position = tok.value
                else
                  return BuilderError(ln,
                    "invalid tabs position: " + tok.value)
                end
              end
            end
          end
        end

        // Create widget — interpose wrapper for tabs= stacks so the
        // Stack's immutable parent points to the wrapper from birth.
        var tabs_wrapper: ((VBox tag | HBox tag) | None) = None
        let effective_parent: WidgetParent tag = match tabs_position
        | let pos: String val =>
          let is_vertical = (pos == "north") or (pos == "south")
          if is_vertical then
            let w = VBox(parent)
            tabs_wrapper = w
            w
          else
            let w = HBox(parent)
            tabs_wrapper = w
            w
          end
        else
          parent
        end

        let widget: Widget tag = factory(effective_parent)

        // wire_widget is what gets wired to the DSL parent — the wrapper
        // when tabs= is present, or the widget itself otherwise
        let wire_widget: Widget tag = match tabs_wrapper
        | let v: VBox tag => v
        | let h: HBox tag => h
        else
          widget
        end

        // Track wrapper for post-parse TabBar addition
        match (tabs_position, tabs_wrapper)
        | (let pos: String val, let wrapper: (VBox tag | HBox tag)) =>
          match widget
          | let sw: Stack tag =>
            stacks_needing_tabs.push(
              (wrapper, sw, pos, Array[(String val, String val)]))
          end
        end

        // Process remaining tokens
        var primary_text: (String | None) = None
        var widget_id: (String | None) = None
        var focusable: Bool = false

        for ti in Range(1, tokens.size()) do
          try
            let tok = tokens(ti)?
            match tok.kind
            | TokId =>
              widget_id = tok.value
            | TokQuotedString =>
              primary_text = tok.value
            | TokKeyValue =>
              match _apply_property(widget, type_name, tok.key, tok.value, ln)
              | let err: BuilderError => return err
              end
            | TokWord =>
              if tok.value == "focusable" then
                focusable = true
              else
                return BuilderError(ln,
                  "unexpected token: " + tok.value)
              end
            end
          end
        end

        // Apply primary text
        match primary_text
        | let text: String =>
          match type_name
          | "label" =>
            match widget
            | let l: Label tag => l.set_text(text)
            end
          | "frame" =>
            match widget
            | let f: Frame tag => f.set_title(text)
            end
          | "textbox" =>
            match widget
            | let tb: TextBox tag => tb.set_text(text)
            end
          end
        end

        // Store by #id
        match widget_id
        | let id: String =>
          _widgets_by_id(id) = widget
        end

        // Wire to parent — use wire_widget so the wrapper (not the
        // Stack) is what the DSL parent sees when tabs= is active.
        match pending_pack
        | (let pi: USize, let is_start: Bool, let pw: USize, let ph: USize,
           let po: PackOption) =>
          if stack.size() > 0 then
            try
              (_, let parent_widget, _) = stack(stack.size() - 1)?
              if is_start then
                match parent_widget
                | let vb: VBox tag => vb.pack_start(wire_widget, pw, ph, po)
                | let hb: HBox tag => hb.pack_start(wire_widget, pw, ph, po)
                end
              else
                match parent_widget
                | let vb: VBox tag => vb.pack_end(wire_widget, pw, ph, po)
                | let hb: HBox tag => hb.pack_end(wire_widget, pw, ph, po)
                end
              end
            end
          end
          pending_pack = None
        else
          match pending_add
          | (let ai: USize, let add_name: String val,
             let add_tab: (String val | None)) =>
            if stack.size() > 0 then
              try
                (_, let parent_widget, let parent_type) = stack(stack.size() - 1)?
                if parent_type == "stack" then
                  match parent_widget
                  | let s: Stack tag =>
                    s.add_child(add_name, wire_widget)
                    s.set_input_actor(_input_actor)
                    // Track tab entry for stacks with tabs=
                    for tab_info in stacks_needing_tabs.values() do
                      (_, let tracked_stack, _, let tab_entries) = tab_info
                      if (tracked_stack is s) then
                        let label = match add_tab
                        | let l: String val => l
                        else add_name
                        end
                        tab_entries.push((add_name, label))
                      end
                    end
                  end
                end
              end
            end
            _widgets_by_id(add_name) = widget
            pending_add = None
          else
            if stack.size() > 0 then
              try
                (_, let parent_widget, let parent_type) = stack(stack.size() - 1)?
                if parent_type == "frame" then
                  match parent_widget
                  | let f: Frame tag => f.set_child(wire_widget)
                  end
                end
              end
            end
          end
        end

        // Track root
        match root
        | None => root = wire_widget
        end

        // Push onto stack
        stack.push((indent, widget, type_name))

        // Register focusable (with stack scope if inside a stack child).
        // Must happen after push so the parse stack has the scope entry.
        // Routes through Stack so register_focusable and disable_scope
        // are causally ordered on the InputActor.
        if focusable then
          match _find_stack_and_scope(stack)
          | (let s: Stack tag, let scope: Widget tag) =>
            s._register_focusable(widget, scope)
          else
            _input_actor.register_focusable(widget)
          end
        end
      end
    end

    // Post-parse: add TabBar to pre-created wrappers and pack both
    // children. The wrapper was created during parsing so the Stack's
    // immutable parent already points to it.
    for tab_info in stacks_needing_tabs.values() do
      (let wrapper, let sw, let position, let tab_entries) = tab_info
      if tab_entries.size() == 0 then continue end

      let is_vertical_layout =
        (position == "north") or (position == "south")
      let tab_orient: TabOrientation =
        if is_vertical_layout then TabHorizontal else TabVertical end

      let callback = {(key: String val)(sw) => sw.show(key)} val

      match wrapper
      | let vbox: VBox tag =>
        let tab_bar = TabBar(vbox, callback, tab_orient)
        for te in tab_entries.values() do
          (let key, let label) = te
          tab_bar.add_tab(key, label)
        end
        _input_actor.register_focusable(tab_bar)

        match position
        | "north" =>
          vbox.pack_start(tab_bar, 0, 1, PackOption(PackFixed))
          vbox.pack_start(sw, 0, 0, PackOption(PackFill))
        | "south" =>
          vbox.pack_start(sw, 0, 0, PackOption(PackFill))
          vbox.pack_end(tab_bar, 0, 1, PackOption(PackFixed))
        end
      | let hbox: HBox tag =>
        let tab_bar = TabBar(hbox, callback, tab_orient)
        for te in tab_entries.values() do
          (let key, let label) = te
          tab_bar.add_tab(key, label)
        end
        _input_actor.register_focusable(tab_bar)

        match position
        | "west" =>
          hbox.pack_start(tab_bar, 12, 0, PackOption(PackFixed))
          hbox.pack_start(sw, 0, 0, PackOption(PackFill))
        | "east" =>
          hbox.pack_start(sw, 0, 0, PackOption(PackFill))
          hbox.pack_end(tab_bar, 12, 0, PackOption(PackFixed))
        end
      end
    end

    // Register root for resize and return
    match root
    | let r: Widget tag =>
      _input_actor.register_widget(r)
      r
    else
      BuilderError(0, "empty DSL: no widgets defined")
    end

  fun ref _apply_property(
    widget: Widget tag,
    type_name: String,
    key: String,
    value: String,
    line_num: USize)
    : (None | BuilderError)
  =>
    // Universal: debug-bg
    if key == "debug-bg" then
      match ColorLookup(value)
      | let c: Color => widget.set_debug_bg(c)
        return None
      | None =>
        return BuilderError(line_num, "unknown color: " + value)
      end
    end

    match type_name
    | "label" =>
      match key
      | "fg" =>
        match ColorLookup(value)
        | let c: Color =>
          match widget
          | let l: Label tag => l.set_color(c)
          end
        | None =>
          return BuilderError(line_num, "unknown color: " + value)
        end
      | "bg" =>
        match ColorLookup(value)
        | let c: Color =>
          match widget
          | let l: Label tag => l.set_color(White, c)
          end
        | None =>
          return BuilderError(line_num, "unknown color: " + value)
        end
      | "align" =>
        match AlignLookup(value)
        | let a: Alignment =>
          match widget
          | let l: Label tag => l.set_align(a)
          end
        | None =>
          return BuilderError(line_num, "unknown alignment: " + value)
        end
      else
        return BuilderError(line_num,
          "unknown property '" + key + "' for " + type_name)
      end
    | "frame" =>
      match key
      | "border-color" =>
        match ColorLookup(value)
        | let c: Color =>
          match widget
          | let f: Frame tag => f.set_border_color(c)
          end
        | None =>
          return BuilderError(line_num, "unknown color: " + value)
        end
      else
        return BuilderError(line_num,
          "unknown property '" + key + "' for " + type_name)
      end
    | "hbox" | "vbox" =>
      match key
      | "align" =>
        match AlignLookup(value)
        | let a: Alignment =>
          match type_name
          | "hbox" =>
            match widget
            | let hb: HBox tag => hb.set_align(a)
            end
          | "vbox" =>
            match widget
            | let vb: VBox tag => vb.set_align(a)
            end
          end
        | None =>
          return BuilderError(line_num, "unknown alignment: " + value)
        end
      else
        return BuilderError(line_num,
          "unknown property '" + key + "' for " + type_name)
      end
    | "hline" | "vline" =>
      match key
      | "color" =>
        match ColorLookup(value)
        | let c: Color =>
          match type_name
          | "hline" =>
            match widget
            | let hl: HLine tag => hl.set_color(c)
            end
          | "vline" =>
            match widget
            | let vl: VLine tag => vl.set_color(c)
            end
          end
        | None =>
          return BuilderError(line_num, "unknown color: " + value)
        end
      else
        return BuilderError(line_num,
          "unknown property '" + key + "' for " + type_name)
      end
    | "textbox" =>
      match key
      | "fg" =>
        match ColorLookup(value)
        | let c: Color =>
          match widget
          | let tb: TextBox tag => tb.set_color(c)
          end
        | None =>
          return BuilderError(line_num, "unknown color: " + value)
        end
      | "bg" =>
        match ColorLookup(value)
        | let c: Color =>
          match widget
          | let tb: TextBox tag => tb.set_color(White, c)
          end
        | None =>
          return BuilderError(line_num, "unknown color: " + value)
        end
      | "wrap" =>
        match widget
        | let tb: TextBox tag => tb.set_wrap(value == "true")
        end
      else
        return BuilderError(line_num,
          "unknown property '" + key + "' for " + type_name)
      end
    | "stack" =>
      match key
      | "tabs" => None  // Validated and applied in build() inline
      else
        return BuilderError(line_num,
          "unknown property '" + key + "' for " + type_name)
      end
    | "tabbar" =>
      match key
      | "orientation" => None  // Set at construction
      else
        return BuilderError(line_num,
          "unknown property '" + key + "' for " + type_name)
      end
    else
      return BuilderError(line_num,
        "unknown property '" + key + "' for " + type_name)
    end
    None

  fun _find_stack_and_scope(
    stack: Array[(USize, Widget tag, String)])
    : ((Stack tag, Widget tag) | None)
  =>
    """
    Walk the parse stack looking for a "stack" entry. Returns the Stack and
    its direct child (the focus scope widget). The child is the entry
    immediately after the stack in the parse stack.
    """
    var i: USize = 0
    while i < stack.size() do
      try
        (_, let stack_widget, let tn) = stack(i)?
        if tn == "stack" then
          try
            (_, let child_widget, _) = stack(i + 1)?
            match (stack_widget, child_widget)
            | (let s: Stack tag, let c: Widget tag) =>
              return (s, c)
            end
          end
        end
      end
      i = i + 1
    end
    None

  fun _strip_block_comments(input: String): String =>
    recover val
      let result = String(input.size())
      var in_block: Bool = false
      var i: USize = 0
      while i < input.size() do
        try
          if in_block then
            if (input(i)? == '*') and ((i + 1) < input.size())
              and (input(i + 1)? == '/')
            then
              in_block = false
              i = i + 2
              continue
            end
            // Preserve newlines for line counting
            if input(i)? == '\n' then
              result.push('\n')
            end
            i = i + 1
          else
            if (input(i)? == '/') and ((i + 1) < input.size())
              and (input(i + 1)? == '*')
            then
              in_block = true
              i = i + 2
              continue
            end
            result.push(input(i)?)
            i = i + 1
          end
        else
          break
        end
      end
      result
    end
