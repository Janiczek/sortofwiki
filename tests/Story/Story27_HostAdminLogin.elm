module Story.Story27_HostAdminLogin exposing (suite)

import Effect.Test
import ProgramTest.Story27_HostAdminLogin
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 27 — host admin login"
        (List.map Effect.Test.toTest ProgramTest.Story27_HostAdminLogin.endToEndTests)
