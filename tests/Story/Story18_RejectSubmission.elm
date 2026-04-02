module Story.Story18_RejectSubmission exposing (suite)

import Effect.Test
import ProgramTest.Story18_RejectSubmission
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 18 — reject submission"
        (List.map Effect.Test.toTest ProgramTest.Story18_RejectSubmission.endToEndTests)
