module Story.Story34_ModerationAuditTrail exposing (suite)

import Effect.Test
import ProgramTest.Story34_ModerationAuditTrail
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 34 — moderation decisions in audit log"
        (List.map Effect.Test.toTest ProgramTest.Story34_ModerationAuditTrail.endToEndTests)
