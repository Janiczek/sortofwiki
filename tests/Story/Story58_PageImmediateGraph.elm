module Story.Story58_PageImmediateGraph exposing (suite)

import Effect.Test
import ProgramTest.Story58_PageImmediateGraph
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 58 — page immediate graph"
        (List.map Effect.Test.toTest ProgramTest.Story58_PageImmediateGraph.endToEndTests)
