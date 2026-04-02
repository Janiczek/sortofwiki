module Story.Story25_AuditLog exposing (suite)

import Effect.Test
import ProgramTest.Story25_AuditLog
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 25 — wiki admin audit log"
        (List.map Effect.Test.toTest ProgramTest.Story25_AuditLog.endToEndTests)
