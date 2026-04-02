module Story.Story21_PromoteTrusted exposing (suite)

import Effect.Test
import ProgramTest.Story21_PromoteTrusted
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 21 — promote contributor to trusted"
        (List.map Effect.Test.toTest ProgramTest.Story21_PromoteTrusted.endToEndTests)
