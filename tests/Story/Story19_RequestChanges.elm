module Story.Story19_RequestChanges exposing (suite)

import Effect.Test
import ProgramTest.Story19_RequestChanges
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 19 — request changes with guidance"
        (List.map Effect.Test.toTest ProgramTest.Story19_RequestChanges.endToEndTests)
