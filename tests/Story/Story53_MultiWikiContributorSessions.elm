module Story.Story53_MultiWikiContributorSessions exposing (suite)

import Effect.Test
import ProgramTest.Story53_MultiWikiContributorSessions
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 53 — multi-wiki contributor sessions"
        (List.map Effect.Test.toTest ProgramTest.Story53_MultiWikiContributorSessions.endToEndTests)
