module Story.Story32_DeleteHostedWiki exposing (suite)

import Effect.Test
import ProgramTest.Story32_DeleteHostedWiki
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 32 — host admin delete hosted wiki"
        (List.map Effect.Test.toTest ProgramTest.Story32_DeleteHostedWiki.endToEndTests)
