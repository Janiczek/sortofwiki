module Story.Story49_MissingPageNavAndWikiLinks exposing (suite)

import Effect.Test
import ProgramTest.Story49_MissingPageNavAndWikiLinks
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 49 — missing page UI, nav, wiki links"
        (List.map Effect.Test.toTest ProgramTest.Story49_MissingPageNavAndWikiLinks.endToEndTests)
