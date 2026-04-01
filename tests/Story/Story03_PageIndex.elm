module Story.Story03_PageIndex exposing (suite)

import Effect.Test
import ProgramTest.Story03_PageIndex
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 03 — page index"
        (List.map Effect.Test.toTest ProgramTest.Story03_PageIndex.endToEndTests)
