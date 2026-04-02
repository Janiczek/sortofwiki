module Story.Story09_NewPageSubmission exposing (suite)

import Effect.Test
import ProgramTest.Story09_NewPageSubmission
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 09 — new page submission"
        (List.map Effect.Test.toTest ProgramTest.Story09_NewPageSubmission.endToEndTests)
