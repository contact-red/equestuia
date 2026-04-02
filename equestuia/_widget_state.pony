class ref WidgetState
  """
  Bundles the common fields every widget needs. Stored as a single field
  on the actor and exposed via `fun ref state(): WidgetState`. The Widget
  and CompositeWidget traits use this to provide default implementations
  without requiring seven boilerplate accessors.
  """
  let parent: WidgetParent tag
  var width: USize = 0
  var height: USize = 0
  let child_grids: Array[(Any tag, Grid)]
  var dirty: Bool = false

  new create(parent': WidgetParent tag) =>
    parent = parent'
    child_grids = Array[(Any tag, Grid)]
