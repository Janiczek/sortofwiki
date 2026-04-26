module Story.Story58_WikiSearch exposing (suite)

import Effect.Test
import ProgramTest.Story58_WikiSearch
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 58 — wiki search"
        (List.map Effect.Test.toTest ProgramTest.Story58_WikiSearch.endToEndTests)
