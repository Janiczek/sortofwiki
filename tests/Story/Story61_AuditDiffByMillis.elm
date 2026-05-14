module Story.Story61_AuditDiffByMillis exposing (suite)

import Effect.Test
import Expect
import ProgramTest.Story61_AuditDiffByMillis as Story61
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Story 61 — wiki admin audit diff URL uses stable event millis"
        [ Test.test "program-test seed resolves KitchenSink trusted publish millis" <|
            \() ->
                Story61.kitchenSinkTrustedPublishAuditAtMillis
                    |> Expect.notEqual -1
        , Test.describe "end-to-end"
            (List.map Effect.Test.toTest Story61.endToEndTests)
        ]
