module Story.Story23_GrantWikiAdmin exposing (suite)

import Effect.Test
import ProgramTest.Story23_GrantWikiAdmin
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 23 — grant wiki admin to trusted contributor"
        (List.map Effect.Test.toTest ProgramTest.Story23_GrantWikiAdmin.endToEndTests)
