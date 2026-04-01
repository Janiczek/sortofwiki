module Story.Story04_PublishedPage exposing (suite)

import Effect.Test
import ProgramTest.Story04_PublishedPage
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 04 — published page"
        (List.map Effect.Test.toTest ProgramTest.Story04_PublishedPage.endToEndTests)
