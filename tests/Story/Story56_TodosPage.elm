module Story.Story56_TodosPage exposing (suite)

import Effect.Test
import ProgramTest.Story56_TodosPage
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 56 — TODO syntax and TODOs page"
        (List.map Effect.Test.toTest ProgramTest.Story56_TodosPage.endToEndTests)
