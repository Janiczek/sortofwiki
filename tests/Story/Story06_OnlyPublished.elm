module Story.Story06_OnlyPublished exposing (suite)

import Effect.Test
import ProgramTest.Story06_OnlyPublished
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 06 — only published revisions"
        (List.map Effect.Test.toTest ProgramTest.Story06_OnlyPublished.endToEndTests)
