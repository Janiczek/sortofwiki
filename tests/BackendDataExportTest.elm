module BackendDataExportTest exposing (suite)

import BackendDataExport
import Dict exposing (Dict)
import Expect
import PendingReviewCount
import ProgramTest.Config
import Set
import Submission exposing (Submission)
import Test exposing (Test)
import Types exposing (BackendModel)
import Wiki exposing (Wiki)
import WikiAuditLog
import WikiContributors
import WikiUser


fixtureModel : BackendModel
fixtureModel =
    ProgramTest.Config.replayInitStepsOntoModel ProgramTest.Config.demoWikiModerationSteps


suite : Test
suite =
    Test.describe "BackendDataExport"
        [ Test.test "encode then decode round-trips fixture model (excluding host sessions and counter)" <|
            \() ->
                let
                    json : String
                    json =
                        BackendDataExport.encodeModelToJsonString fixtureModel

                    snapResult : Result BackendDataExport.ImportError BackendDataExport.SnapshotFields
                    snapResult =
                        BackendDataExport.decodeImportString json
                in
                case snapResult of
                    Err e ->
                        Expect.fail (BackendDataExport.importErrorToString e)

                    Ok snap ->
                        let
                            restored : BackendModel
                            restored =
                                BackendDataExport.applySnapshotToBackendModel snap Set.empty
                        in
                        Expect.all
                            [ \() -> restored.wikis |> Expect.equal fixtureModel.wikis
                            , \() -> restored.contributors |> Expect.equal fixtureModel.contributors
                            , \() -> restored.contributorSessions |> Expect.equal WikiUser.emptySessions
                            , \() -> restored.submissions |> Expect.equal fixtureModel.submissions
                            , \() -> restored.wikiAuditEvents |> Expect.equal fixtureModel.wikiAuditEvents
                            , \() -> restored.hostSessions |> Expect.equal Set.empty
                            , \() ->
                                restored.pendingReviewCounts
                                    |> Expect.equal (PendingReviewCount.recallFromSubmissions fixtureModel.submissions)
                            , \() ->
                                restored.nextSubmissionCounter
                                    |> Expect.equal
                                        (BackendDataExport.nextSubmissionCounterFromSubmissions fixtureModel.submissions)
                            ]
                            ()
        , Test.test "nextSubmissionCounterFromSubmissions is one past max sub_N id" <|
            \() ->
                let
                    m : BackendModel
                    m =
                        fixtureModel
                in
                BackendDataExport.nextSubmissionCounterFromSubmissions m.submissions
                    |> Expect.equal m.nextSubmissionCounter
        , Test.test "wiki snapshot encode/decode round-trip for Demo slice" <|
            \() ->
                case BackendDataExport.encodeWikiSnapshotToJsonString "Demo" fixtureModel of
                    Nothing ->
                        Expect.fail "expected Demo wiki in fixture"

                    Just wikiJson ->
                        case BackendDataExport.decodeWikiImportForSlug "Demo" wikiJson of
                            Err e ->
                                Expect.fail (BackendDataExport.importErrorToString e)

                            Ok snap ->
                                let
                                    demoWikis : Dict Wiki.Slug Wiki
                                    demoWikis =
                                        fixtureModel.wikis
                                            |> Dict.filter (\slug _ -> slug == "Demo")

                                    demoSubs : Dict String Submission
                                    demoSubs =
                                        fixtureModel.submissions
                                            |> Dict.filter (\_ sub -> sub.wikiSlug == "Demo")

                                    demoContributors : Dict String (Dict String WikiContributors.StoredContributor)
                                    demoContributors =
                                        fixtureModel.contributors
                                            |> Dict.filter (\slug _ -> slug == "Demo")

                                    demoAuditRows : List WikiAuditLog.AuditEvent
                                    demoAuditRows =
                                        fixtureModel.wikiAuditEvents
                                            |> Dict.get "Demo"
                                            |> Maybe.withDefault []
                                in
                                Expect.all
                                    [ \() -> snap.wikis |> Expect.equal demoWikis
                                    , \() -> snap.submissions |> Expect.equal demoSubs
                                    , \() -> snap.contributors |> Expect.equal demoContributors
                                    , \() -> snap.contributorSessions |> Expect.equal WikiUser.emptySessions
                                    , \() ->
                                        snap.wikiAuditEvents
                                            |> Expect.equal (Dict.singleton "Demo" demoAuditRows)
                                    ]
                                    ()
        , Test.test "wiki snapshot merge restores Demo after clearing its pages" <|
            \() ->
                case BackendDataExport.encodeWikiSnapshotToJsonString "Demo" fixtureModel of
                    Nothing ->
                        Expect.fail "expected Demo wiki in fixture"

                    Just wikiJson ->
                        case BackendDataExport.decodeWikiImportForSlug "Demo" wikiJson of
                            Err e ->
                                Expect.fail (BackendDataExport.importErrorToString e)

                            Ok snap ->
                                case Dict.get "Demo" fixtureModel.wikis of
                                    Nothing ->
                                        Expect.fail "fixture must include Demo wiki"

                                    Just wiki ->
                                        let
                                            damagedModel : BackendModel
                                            damagedModel =
                                                { fixtureModel
                                                    | wikis =
                                                        Dict.insert "Demo" { wiki | pages = Dict.empty } fixtureModel.wikis
                                                }
                                        in
                                        case BackendDataExport.applyWikiSnapshotMerge "Demo" snap damagedModel of
                                            Err msg ->
                                                Expect.fail msg

                                            Ok merged ->
                                                Dict.get "Demo" merged.wikis
                                                    |> Expect.equal (Dict.get "Demo" fixtureModel.wikis)
        , Test.test "wiki snapshot import rejects slug different from selected row" <|
            \() ->
                case BackendDataExport.encodeWikiSnapshotToJsonString "Demo" fixtureModel of
                    Nothing ->
                        Expect.fail "expected Demo wiki in fixture"

                    Just wikiJson ->
                        case BackendDataExport.decodeWikiImportForSlug "ElmTips" wikiJson of
                            Ok _ ->
                                Expect.fail "expected decode error for slug mismatch"

                            Err _ ->
                                Expect.pass
        ]
