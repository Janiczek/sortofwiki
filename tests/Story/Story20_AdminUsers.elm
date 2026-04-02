module Story.Story20_AdminUsers exposing (suite)

import Effect.Test
import ProgramTest.Story20_AdminUsers
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 20 — wiki admin users page"
        (List.map Effect.Test.toTest ProgramTest.Story20_AdminUsers.endToEndTests)
