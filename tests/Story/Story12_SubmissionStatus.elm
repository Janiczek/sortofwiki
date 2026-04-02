module Story.Story12_SubmissionStatus exposing (suite)

import Effect.Test
import ProgramTest.Story12_SubmissionStatus
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 12 — submission status for contributor"
        (List.map Effect.Test.toTest ProgramTest.Story12_SubmissionStatus.endToEndTests)
