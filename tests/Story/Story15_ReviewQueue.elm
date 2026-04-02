module Story.Story15_ReviewQueue exposing (suite)

import Effect.Test
import ProgramTest.Story15_ReviewQueue
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 15 — review queue"
        (List.map Effect.Test.toTest ProgramTest.Story15_ReviewQueue.endToEndTests)
