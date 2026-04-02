module Story.Story07_Register exposing (suite)

import Effect.Test
import ProgramTest.Story07_Register
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 07 — register contributor"
        (List.map Effect.Test.toTest ProgramTest.Story07_Register.endToEndTests)
