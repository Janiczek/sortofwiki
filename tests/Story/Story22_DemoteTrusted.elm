module Story.Story22_DemoteTrusted exposing (suite)

import Effect.Test
import ProgramTest.Story22_DemoteTrusted
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 22 — demote trusted to contributor"
        (List.map Effect.Test.toTest ProgramTest.Story22_DemoteTrusted.endToEndTests)
