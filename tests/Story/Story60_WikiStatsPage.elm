module Story.Story60_WikiStatsPage exposing (suite)

import Effect.Test
import ProgramTest.Story60_WikiStatsPage
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 60 — wiki stats page"
        (List.map Effect.Test.toTest ProgramTest.Story60_WikiStatsPage.endToEndTests)
