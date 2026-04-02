module Story.Story29_CreateHostedWiki exposing (suite)

import Effect.Test
import ProgramTest.Story29_CreateHostedWiki
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 29 — host admin create hosted wiki"
        (List.map Effect.Test.toTest ProgramTest.Story29_CreateHostedWiki.endToEndTests)
