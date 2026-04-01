module Story.Story01_WikiList exposing (suite)

import Effect.Test
import ProgramTest.Story01_WikiList
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 1 — wiki list catalog"
        (List.map Effect.Test.toTest ProgramTest.Story01_WikiList.endToEndTests)
