module Story.Story16_ReviewSubmissionDiff exposing (suite)

import Effect.Test
import ProgramTest.Story16_ReviewSubmissionDiff
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 16 — review submission diff"
        (List.map Effect.Test.toTest ProgramTest.Story16_ReviewSubmissionDiff.endToEndTests)
