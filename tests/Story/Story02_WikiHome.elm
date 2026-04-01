module Story.Story02_WikiHome exposing (suite)

import Effect.Test
import ProgramTest.Story02_WikiHome
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 02 — wiki home"
        (List.map Effect.Test.toTest ProgramTest.Story02_WikiHome.endToEndTests)
