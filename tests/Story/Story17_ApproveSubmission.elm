module Story.Story17_ApproveSubmission exposing (suite)

import Effect.Test
import ProgramTest.Story17_ApproveSubmission
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 17 — approve submission"
        (List.map Effect.Test.toTest ProgramTest.Story17_ApproveSubmission.endToEndTests)
