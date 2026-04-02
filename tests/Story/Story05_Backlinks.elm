module Story.Story05_Backlinks exposing (suite)

import Effect.Test
import ProgramTest.Story05_Backlinks
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 05 — backlinks"
        (List.map Effect.Test.toTest ProgramTest.Story05_Backlinks.endToEndTests)
