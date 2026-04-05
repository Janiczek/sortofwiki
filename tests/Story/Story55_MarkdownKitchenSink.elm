module Story.Story55_MarkdownKitchenSink exposing (suite)

import Effect.Test
import ProgramTest.Story55_MarkdownKitchenSink
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 55 — kitchen-sink markdown and math custom elements"
        (List.map Effect.Test.toTest ProgramTest.Story55_MarkdownKitchenSink.endToEndTests)
