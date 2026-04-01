use "collections"

primitive Horizontal
primitive Vertical
type PackAxis is (Horizontal | Vertical)

class val Allocation
  let x: USize
  let y: USize
  let width: USize
  let height: USize

  new val create(x': USize, y': USize, width': USize, height': USize) =>
    x = x'
    y = y'
    width = width'
    height = height'

primitive Packer
  fun pack(
    axis: PackAxis,
    container_w: USize,
    container_h: USize,
    children: Array[(SizeHint, PackOption)] val)
    : Array[Allocation] val
  =>
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
        end
      end
    end

    let used = total_preferred + total_padding
    let extra: USize = if used < container_main then
      container_main - used
    else
      0
    end

    let extra_per_expand: USize = if expand_count > 0 then
      extra / expand_count
    else
      0
    end
    let extra_remainder: USize = if expand_count > 0 then
      extra - (extra_per_expand * expand_count)
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

    // Track which expand child is the last one (gets remainder).
    var last_expand_idx: USize = 0
    for ei in Range(0, children.size()) do
      try
        (_, let opt) = children(ei)?
        if opt.expand then
          last_expand_idx = ei
        end
      end
    end

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
        if opt.expand then
          let bonus = if i == last_expand_idx then
            extra_per_expand + extra_remainder
          else
            extra_per_expand
          end
          alloc_space = pref + bonus
        end

        let clamped_space = alloc_space.min(remaining)

        let main_pos: USize = if opt.expand and (not opt.fill) then
          let centered_offset = (clamped_space - pref.min(clamped_space)) / 2
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
        | Horizontal => hint.preferred_height
        | Vertical => hint.preferred_width
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
    var end_cursor: USize = container_main
    for i in end_indices.values() do
      try
        (let hint, let opt) = children(i)?
        let pref = match axis
        | Horizontal => hint.preferred_width
        | Vertical => hint.preferred_height
        end

        let alloc_space: USize = pref
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
        | Horizontal => hint.preferred_height
        | Vertical => hint.preferred_width
        end

        let alloc = match axis
        | Horizontal => Allocation(main_pos, 0, size, cross_size)
        | Vertical => Allocation(0, main_pos, cross_size, size)
        end
        result(i)? = consume alloc
      end
    end

    consume result
