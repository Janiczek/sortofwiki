module Story.Story51_HostAdminAuditLog exposing (suite)

import Effect.Test
import ProgramTest.Story51_HostAdminAuditLog
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 51 — host admin audit log"
        (List.map Effect.Test.toTest ProgramTest.Story51_HostAdminAuditLog.endToEndTests)
