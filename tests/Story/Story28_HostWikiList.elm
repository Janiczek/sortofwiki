module Story.Story28_HostWikiList exposing (suite)

import Effect.Test
import ProgramTest.Story28_HostWikiList
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 28 — host admin wiki list"
        (List.map Effect.Test.toTest ProgramTest.Story28_HostWikiList.endToEndTests)
