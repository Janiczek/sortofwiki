module Story.Story47_FrontendRouteGuards exposing (suite)

import Effect.Test
import ProgramTest.Story47_FrontendRouteGuards
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 47 — frontend route guards and login redirects"
        (List.map Effect.Test.toTest ProgramTest.Story47_FrontendRouteGuards.endToEndTests)
