use "pony_test"
use "pony_check"
use "collections"

class \nodoc\ iso _TestPackerSingleChild is UnitTest
  fun name(): String => "Packer.single_child"

  fun apply(h: TestHelper) =>
    let children = recover val
      Array[(USize, USize, PackOption)](1)
        .> push((10, 5, PackOption))
    end
    let result = Packer.pack(Horizontal, 80, 24, children)
    h.assert_eq[USize](1, result.size())
    try
      let alloc = result(0)?
      h.assert_eq[USize](0, alloc.x)
      h.assert_eq[USize](0, alloc.y)
      h.assert_eq[USize](10, alloc.width)
      h.assert_eq[USize](24, alloc.height) // cross-axis fills container
    else
      h.fail("index error")
    end

class \nodoc\ iso _TestPackerTwoChildrenHorizontal is UnitTest
  fun name(): String => "Packer.two_children_horizontal"

  fun apply(h: TestHelper) =>
    let children = recover val
      Array[(USize, USize, PackOption)](2)
        .> push((10, 5, PackOption))
        .> push((20, 5, PackOption))
    end
    let result = Packer.pack(Horizontal, 80, 24, children)
    h.assert_eq[USize](2, result.size())
    try
      h.assert_eq[USize](0, result(0)?.x)
      h.assert_eq[USize](10, result(0)?.width)
      h.assert_eq[USize](10, result(1)?.x)
      h.assert_eq[USize](20, result(1)?.width)
    else
      h.fail("index error")
    end

class \nodoc\ iso _TestPackerTwoChildrenVertical is UnitTest
  fun name(): String => "Packer.two_children_vertical"

  fun apply(h: TestHelper) =>
    let children = recover val
      Array[(USize, USize, PackOption)](2)
        .> push((10, 5, PackOption))
        .> push((10, 8, PackOption))
    end
    let result = Packer.pack(Vertical, 80, 24, children)
    h.assert_eq[USize](2, result.size())
    try
      h.assert_eq[USize](0, result(0)?.y)
      h.assert_eq[USize](5, result(0)?.height)
      h.assert_eq[USize](5, result(1)?.y)
      h.assert_eq[USize](8, result(1)?.height)
    else
      h.fail("index error")
    end

class \nodoc\ iso _TestPackerPadding is UnitTest
  fun name(): String => "Packer.padding"

  fun apply(h: TestHelper) =>
    let children = recover val
      Array[(USize, USize, PackOption)](2)
        .> push((10, 5, PackOption(where padding' = 2)))
        .> push((10, 5, PackOption(where padding' = 2)))
    end
    let result = Packer.pack(Horizontal, 80, 24, children)
    h.assert_eq[USize](2, result.size())
    try
      // First child at x=2 (padding before)
      h.assert_eq[USize](2, result(0)?.x)
      // Second child at x=10+2+2 = 14 (first width + first padding + second padding)
      h.assert_eq[USize](14, result(1)?.x)
    else
      h.fail("index error")
    end

class \nodoc\ iso _TestPackerExpand is UnitTest
  fun name(): String => "Packer.expand"

  fun apply(h: TestHelper) =>
    let children = recover val
      Array[(USize, USize, PackOption)](2)
        .> push((20, 5, PackOption))
        .> push((10, 5, PackOption(where expand' = true, fill' = true)))
    end
    let result = Packer.pack(Horizontal, 80, 24, children)
    h.assert_eq[USize](2, result.size())
    try
      h.assert_eq[USize](20, result(0)?.width)
      h.assert_eq[USize](60, result(1)?.width)
    else
      h.fail("index error")
    end

class \nodoc\ iso _TestPackerExpandNoFill is UnitTest
  fun name(): String => "Packer.expand_no_fill"

  fun apply(h: TestHelper) =>
    let children = recover val
      Array[(USize, USize, PackOption)](2)
        .> push((20, 5, PackOption))
        .> push((10, 5, PackOption(where expand' = true, fill' = false)))
    end
    let result = Packer.pack(Horizontal, 80, 24, children)
    try
      h.assert_eq[USize](10, result(1)?.width)
      // Centered in allocated space of 60: x = 20 + ((60 - 10) / 2) = 45
      h.assert_eq[USize](45, result(1)?.x)
    else
      h.fail("index error")
    end

class \nodoc\ iso _TestPackerFromEnd is UnitTest
  fun name(): String => "Packer.from_end"

  fun apply(h: TestHelper) =>
    let children = recover val
      Array[(USize, USize, PackOption)](2)
        .> push((10, 5, PackOption))
        .> push((10, 5, PackOption(where from_end' = true)))
    end
    let result = Packer.pack(Horizontal, 80, 24, children)
    h.assert_eq[USize](2, result.size())
    try
      h.assert_eq[USize](0, result(0)?.x)
      h.assert_eq[USize](70, result(1)?.x)
    else
      h.fail("index error")
    end

class \nodoc\ iso _TestPackerOverflow is UnitTest
  fun name(): String => "Packer.overflow_truncates"

  fun apply(h: TestHelper) =>
    let children = recover val
      Array[(USize, USize, PackOption)](2)
        .> push((50, 5, PackOption))
        .> push((50, 5, PackOption))
    end
    let result = Packer.pack(Horizontal, 80, 24, children)
    try
      h.assert_eq[USize](50, result(0)?.width)
      h.assert_eq[USize](30, result(1)?.width)
    else
      h.fail("index error")
    end

class \nodoc\ iso _PropPackerTotalFitsContainer is Property1[_PackerSample]
  """Property: total allocated size along packing axis never exceeds container."""
  fun name(): String => "Packer.total_fits_container"

  fun gen(): Generator[_PackerSample] =>
    Generators.map2[USize, USize, _PackerSample](
      Generators.usize(10, 100),
      Generators.usize(1, 5),
      {(container_size, num_children) => (container_size, num_children) })

  fun property(sample: _PackerSample, h: PropertyHelper) =>
    (let container_size, let num_children) = sample
    let children = recover val
      let arr = Array[(USize, USize, PackOption)](num_children)
      for i in Range(0, num_children) do
        arr.push((5, 3, PackOption))
      end
      arr
    end
    let result = Packer.pack(Horizontal, container_size, 100, children)
    var total: USize = 0
    for alloc in result.values() do
      total = total + alloc.width
    end
    h.assert_true(total <= container_size,
      "total " + total.string() + " > container " + container_size.string())

class \nodoc\ iso _PropPackerExpandFillsExactly is Property1[_PackerExpandSample]
  """Property: when all children expand+fill, total equals container exactly."""
  fun name(): String => "Packer.expand_fills_exactly"

  fun gen(): Generator[_PackerExpandSample] =>
    Generators.map2[USize, USize, _PackerExpandSample](
      Generators.usize(20, 200),
      Generators.usize(1, 5),
      {(container_size, num_children) => (container_size, num_children) })

  fun property(sample: _PackerExpandSample, h: PropertyHelper) =>
    (let container_size, let num_children) = sample
    let children = recover val
      let arr = Array[(USize, USize, PackOption)](num_children)
      for i in Range(0, num_children) do
        arr.push((3, 3, PackOption(where expand' = true, fill' = true)))
      end
      arr
    end
    let result = Packer.pack(Horizontal, container_size, 100, children)
    var total: USize = 0
    for alloc in result.values() do
      total = total + alloc.width
    end
    h.assert_eq[USize](container_size, total)

type _PackerSample is (USize, USize)
type _PackerExpandSample is (USize, USize)
