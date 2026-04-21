module Story.Story57_WikiGraphPage exposing (suite)

import Effect.Test
import ProgramTest.Story57_WikiGraphPage
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 57 — wiki graph page"
        (List.map Effect.Test.toTest ProgramTest.Story57_WikiGraphPage.endToEndTests)
