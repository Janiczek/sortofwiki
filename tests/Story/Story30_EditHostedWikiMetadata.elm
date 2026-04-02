module Story.Story30_EditHostedWikiMetadata exposing (suite)

import Effect.Test
import ProgramTest.Story30_EditHostedWikiMetadata
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 30 — edit hosted wiki metadata (program)"
        (List.map Effect.Test.toTest ProgramTest.Story30_EditHostedWikiMetadata.endToEndTests)
