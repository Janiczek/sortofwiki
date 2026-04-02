module Story.Story14_TrustedDirectPublish exposing (suite)

import Effect.Test
import ProgramTest.Story14_TrustedDirectPublish
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 14 — trusted direct publish"
        (List.map Effect.Test.toTest ProgramTest.Story14_TrustedDirectPublish.endToEndTests)
