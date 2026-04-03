module Story.Story48_ConcurrentEditConflicts exposing (suite)

import Effect.Test
import ProgramTest.Story48_ConcurrentEditConflicts
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 48 — concurrent edits: approve one, resolve other, approve second"
        (List.map Effect.Test.toTest ProgramTest.Story48_ConcurrentEditConflicts.endToEndTests)
