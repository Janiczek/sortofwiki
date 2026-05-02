module Story.Story59_SubmissionDetailTrustedRedirect exposing (suite)

import Effect.Test
import ProgramTest.Story59_SubmissionDetailTrustedRedirect
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 59 — trusted cannot use contributor submit detail for others' submissions"
        (List.map Effect.Test.toTest ProgramTest.Story59_SubmissionDetailTrustedRedirect.endToEndTests)
