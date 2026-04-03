module Story.Story52_HostAdminWikiBackup exposing (suite)

import Effect.Test
import ProgramTest.Story52_HostAdminWikiBackup
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 52 — host admin per-wiki JSON backup"
        (List.map Effect.Test.toTest ProgramTest.Story52_HostAdminWikiBackup.endToEndTests)
