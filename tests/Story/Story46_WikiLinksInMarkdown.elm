module Story.Story46_WikiLinksInMarkdown exposing (suite)

import Effect.Test
import ProgramTest.Story46_WikiLinksInMarkdown
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 46 — wiki links in published markdown"
        (List.map Effect.Test.toTest ProgramTest.Story46_WikiLinksInMarkdown.endToEndTests)
