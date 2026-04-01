module Story.Story35_NotFound exposing (suite)

import Effect.Test
import ProgramTest.Story35_NotFound
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 35 — 404 unknown URL"
        (List.map Effect.Test.toTest ProgramTest.Story35_NotFound.endToEndTests)
