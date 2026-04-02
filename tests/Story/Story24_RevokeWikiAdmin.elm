module Story.Story24_RevokeWikiAdmin exposing (suite)

import Effect.Test
import ProgramTest.Story24_RevokeWikiAdmin
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 24 — revoke wiki admin (UI + registry)"
        (List.map Effect.Test.toTest ProgramTest.Story24_RevokeWikiAdmin.endToEndTests)
