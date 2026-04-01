use "collections"

primitive Differ
  fun diff(prev: Grid, curr: Grid): Array[(USize, USize, Cell)] val =>
    """
    Compare two grids cell-by-cell and return (col, row, Cell) for each
    changed cell. If dimensions differ, treat as full redraw of curr.
    """
    if (prev.width != curr.width) or (prev.height != curr.height) then
      _full_redraw(curr)
    else
      recover val
        let changes = Array[(USize, USize, Cell)]
        for row in Range(0, curr.height) do
          for col in Range(0, curr.width) do
            match (prev(col, row), curr(col, row))
            | (let p: Cell, let c: Cell) =>
              if p != c then
                changes.push((col, row, c))
              end
            end
          end
        end
        changes
      end
    end

  fun _full_redraw(curr: Grid): Array[(USize, USize, Cell)] val =>
    recover val
      let changes = Array[(USize, USize, Cell)]
      for row in Range(0, curr.height) do
        for col in Range(0, curr.width) do
          match curr(col, row)
          | let c: Cell => changes.push((col, row, c))
          end
        end
      end
      changes
    end
