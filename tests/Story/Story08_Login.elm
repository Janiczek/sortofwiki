module Story.Story08_Login exposing (suite)

import Effect.Test
import ProgramTest.Story08_Login
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 08 — login contributor"
        (List.map Effect.Test.toTest ProgramTest.Story08_Login.endToEndTests)
