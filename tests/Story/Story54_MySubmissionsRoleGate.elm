module Story.Story54_MySubmissionsRoleGate exposing (suite)

import Effect.Test
import ProgramTest.Story54_MySubmissionsRoleGate
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 54 — My Submissions role gate"
        (List.map Effect.Test.toTest ProgramTest.Story54_MySubmissionsRoleGate.endToEndTests)
