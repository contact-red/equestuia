use "collections"

primitive Horizontal
  """
  Pack children along the horizontal axis (left-to-right).
  """
primitive Vertical
  """
  Pack children along the vertical axis (top-to-bottom).
  """
type PackAxis is (Horizontal | Vertical)

class val Allocation
  """
  Result of packing: a child's position and size within the container.
  """
  let x: USize
  let y: USize
  let width: USize
  let height: USize

  new val create(x': USize, y': USize, width': USize, height': USize) =>
    """
    Create an allocation with absolute position and size.
    """
    x = x'
    y = y'
    width = width'
    height = height'

primitive Packer
  """
  GTK2-style box packing algorithm. Computes child allocations given
  container dimensions, packing axis, and children's size hints + pack options.

  When expanding children have more space than needed, extra is distributed
  equally. When there is less space than needed, expanding children shrink
  proportionally. Non-expanding children always get their preferred size
  (truncated only if they physically exceed remaining space).
  """
  fun pack(
    axis: PackAxis,
    container_w: USize,
    container_h: USize,
    children: Array[(SizeHint, PackOption)] val)
    : Array[Allocation] val
  =>
    """
    Compute child allocations within a container. Handles pack_start/pack_end,
    expand/fill, padding, and proportional shrinking.
    """
    let container_main = match axis
    | Horizontal => container_w
    | Vertical => container_h
    end

    // Separate into pack_start and pack_end, preserving original indices.
    let start_indices = Array[USize]
    let end_indices = Array[USize]
    for ci in Range(0, children.size()) do
      try
        (_, let opt) = children(ci)?
        if opt.from_end then
          end_indices.push(ci)
        else
          start_indices.push(ci)
        end
      end
    end

    // Calculate totals for space distribution.
    var total_preferred: USize = 0
    var total_padding: USize = 0
    var expand_count: USize = 0
    var expand_preferred: USize = 0
    var fixed_preferred: USize = 0
    for ti in Range(0, children.size()) do
      try
        (let hint, let opt) = children(ti)?
        let pref = match axis
        | Horizontal => hint.preferred_width
        | Vertical => hint.preferred_height
        end
        total_preferred = total_preferred + pref
        total_padding = total_padding + opt.padding
        if opt.expand then
          expand_count = expand_count + 1
          expand_preferred = expand_preferred + pref
        else
          fixed_preferred = fixed_preferred + pref
        end
      end
    end

    // Space available after padding and fixed children.
    let space_for_expanding: USize =
      if container_main > (total_padding + fixed_preferred) then
        container_main - total_padding - fixed_preferred
      else
        0
      end

    // Build result array with placeholder allocations.
    let result = recover iso
      let arr = Array[Allocation](children.size())
      for _ in Range(0, children.size()) do
        arr.push(Allocation(0, 0, 0, 0))
      end
      arr
    end

    // Compute effective main-axis size for each child.
    // Expanding children share space_for_expanding proportionally.
    // expand_remainder distributes leftover pixels to avoid rounding loss.
    var expand_allocated: USize = 0
    var expand_seen: USize = 0

    // Place pack_start children left-to-right (or top-to-bottom).
    var cursor: USize = 0
    for i in start_indices.values() do
      try
        (let hint, let opt) = children(i)?
        let pref = match axis
        | Horizontal => hint.preferred_width
        | Vertical => hint.preferred_height
        end

        cursor = cursor + opt.padding

        let remaining = if cursor < container_main then
          container_main - cursor
        else
          0
        end

        var alloc_space: USize = pref
        if opt.expand and (expand_count > 0) then
          expand_seen = expand_seen + 1
          if expand_seen == expand_count then
            // Last expanding child gets whatever is left
            alloc_space = if space_for_expanding > expand_allocated then
              space_for_expanding - expand_allocated
            else
              0
            end
          else
            // Proportional share: (pref / expand_preferred) * space_for_expanding
            alloc_space = if expand_preferred > 0 then
              (pref * space_for_expanding) / expand_preferred
            else
              space_for_expanding / expand_count
            end
            expand_allocated = expand_allocated + alloc_space
          end
        end

        let clamped_space = alloc_space.min(remaining)

        let main_pos: USize = if opt.expand and (not opt.fill) then
          let actual_size = pref.min(clamped_space)
          let centered_offset = (clamped_space - actual_size) / 2
          cursor + centered_offset
        else
          cursor
        end

        let main_size: USize = if opt.expand and (not opt.fill) then
          pref.min(clamped_space)
        else
          clamped_space
        end

        let cross_size = match axis
        | Horizontal => container_h
        | Vertical => container_w
        end

        let alloc = match axis
        | Horizontal => Allocation(main_pos, 0, main_size, cross_size)
        | Vertical => Allocation(0, main_pos, cross_size, main_size)
        end
        result(i)? = consume alloc

        cursor = cursor + clamped_space
      end
    end

    // Place pack_end children right-to-left (or bottom-to-top).
    // Reset expand tracking for pack_end group.
    var end_expand_allocated: USize = 0
    var end_expand_seen: USize = 0
    var end_expand_count: USize = 0
    var end_expand_preferred: USize = 0
    var end_fixed_preferred: USize = 0
    var end_total_padding: USize = 0
    for i in end_indices.values() do
      try
        (let hint, let opt) = children(i)?
        let pref = match axis
        | Horizontal => hint.preferred_width
        | Vertical => hint.preferred_height
        end
        end_total_padding = end_total_padding + opt.padding
        if opt.expand then
          end_expand_count = end_expand_count + 1
          end_expand_preferred = end_expand_preferred + pref
        else
          end_fixed_preferred = end_fixed_preferred + pref
        end
      end
    end

    // Space available for pack_end expanding children is from end_cursor backward.
    // end_cursor starts at container_main (or at cursor if pack_start used some).
    var end_cursor: USize = container_main
    let end_space_for_expanding: USize =
      if end_cursor > (end_total_padding + end_fixed_preferred) then
        end_cursor - end_total_padding - end_fixed_preferred
      else
        0
      end

    for i in end_indices.values() do
      try
        (let hint, let opt) = children(i)?
        let pref = match axis
        | Horizontal => hint.preferred_width
        | Vertical => hint.preferred_height
        end

        var alloc_space: USize = pref
        if opt.expand and (end_expand_count > 0) then
          end_expand_seen = end_expand_seen + 1
          if end_expand_seen == end_expand_count then
            alloc_space = if end_space_for_expanding > end_expand_allocated then
              end_space_for_expanding - end_expand_allocated
            else
              0
            end
          else
            alloc_space = if end_expand_preferred > 0 then
              (pref * end_space_for_expanding) / end_expand_preferred
            else
              end_space_for_expanding / end_expand_count
            end
            end_expand_allocated = end_expand_allocated + alloc_space
          end
        end

        let size = if end_cursor >= (alloc_space + opt.padding) then
          alloc_space
        else
          if end_cursor >= opt.padding then
            end_cursor - opt.padding
          else
            0
          end
        end

        end_cursor = if end_cursor >= (size + opt.padding) then
          end_cursor - size - opt.padding
        else
          0
        end

        let main_pos = end_cursor

        let cross_size = match axis
        | Horizontal => container_h
        | Vertical => container_w
        end

        let alloc = match axis
        | Horizontal => Allocation(main_pos, 0, size, cross_size)
        | Vertical => Allocation(0, main_pos, cross_size, size)
        end
        result(i)? = consume alloc
      end
    end

    consume result
