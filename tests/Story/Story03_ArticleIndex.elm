module Story.Story03_ArticleIndex exposing (suite)

import Effect.Test
import ProgramTest.Story03_ArticleIndex
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 03 — article index"
        (List.map Effect.Test.toTest ProgramTest.Story03_ArticleIndex.endToEndTests)
