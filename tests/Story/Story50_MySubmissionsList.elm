module Story.Story50_MySubmissionsList exposing (suite)

import Effect.Test
import ProgramTest.Story50_MySubmissionsList
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 50 — my submissions list"
        (List.map Effect.Test.toTest ProgramTest.Story50_MySubmissionsList.endToEndTests)
