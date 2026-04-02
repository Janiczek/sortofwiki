module Story.Story11_PageDeleteSubmission exposing (suite)

import Effect.Test
import ProgramTest.Story11_PageDeleteSubmission
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 11 — page delete submission"
        (List.map Effect.Test.toTest ProgramTest.Story11_PageDeleteSubmission.endToEndTests)
