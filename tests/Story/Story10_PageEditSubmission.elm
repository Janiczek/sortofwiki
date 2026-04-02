module Story.Story10_PageEditSubmission exposing (suite)

import Effect.Test
import ProgramTest.Story10_PageEditSubmission
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 10 — page edit submission"
        (List.map Effect.Test.toTest ProgramTest.Story10_PageEditSubmission.endToEndTests)
