module Story.Story26_AuditLogFilters exposing (suite)

import Effect.Test
import ProgramTest.Story26_AuditLogFilters
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 26 — audit log filters"
        (List.map Effect.Test.toTest ProgramTest.Story26_AuditLogFilters.endToEndTests)
