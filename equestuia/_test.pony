use "pony_test"
use "pony_check"

actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    test(_TestCellCreate)
    test(_TestCellDefaults)
    test(_TestCellEq)
    test(_TestCellAttrs)
    test(_TestCellWideContinuation)
    test(Property1UnitTest[CellTuple](_PropCellRoundtripEq))
    test(_TestGridCreate)
    test(_TestGridDimensionMismatch)
    test(_TestGridApply)
    test(_TestGridOutOfBounds)
    test(_TestGridFilled)
    test(Property1UnitTest[_GridAccessSample](_PropGridAccessValid))
    test(_TestPackerSingleChild)
    test(_TestPackerTwoChildrenHorizontal)
    test(_TestPackerTwoChildrenVertical)
    test(_TestPackerPadding)
    test(_TestPackerExpand)
    test(_TestPackerExpandNoFill)
    test(_TestPackerFromEnd)
    test(_TestPackerOverflow)
    test(Property1UnitTest[_PackerSample](_PropPackerTotalFitsContainer))
    test(Property1UnitTest[_PackerExpandSample](_PropPackerExpandFillsExactly))
