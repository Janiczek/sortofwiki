module Story.Story31_DeactivateHostedWiki exposing (suite)

import Effect.Test
import ProgramTest.Story31_DeactivateHostedWiki
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 31 — deactivate hosted wiki"
        (List.map Effect.Test.toTest ProgramTest.Story31_DeactivateHostedWiki.endToEndTests)
