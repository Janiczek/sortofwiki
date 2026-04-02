module Story.Story33_BackendAuthorization exposing (suite)

import Effect.Test
import ProgramTest.Story33_BackendAuthorization
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 33 — server-side authorization"
        (List.map Effect.Test.toTest ProgramTest.Story33_BackendAuthorization.endToEndTests)
