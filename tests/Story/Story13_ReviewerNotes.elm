module Story.Story13_ReviewerNotes exposing (suite)

import Effect.Test
import ProgramTest.Story13_ReviewerNotes
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 13 — reviewer notes on rejected / needs-revision submissions"
        (List.map Effect.Test.toTest ProgramTest.Story13_ReviewerNotes.endToEndTests)
