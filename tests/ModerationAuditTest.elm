module ModerationAuditTest exposing (suite)

import Backend
import ContributorAccount
import Dict
import Effect.Lamdera
import Expect
import ProgramTest.Config
import Test exposing (Test)
import Time
import Types exposing (ToBackend(..))
import WikiAuditLog
import WikiUser


sessionKey : String
sessionKey =
    "moderation-audit-test-session"


clientKey : String
clientKey =
    "moderation-audit-test-client"


trustedpubOnDemo : Backend.Model
trustedpubOnDemo =
    let
        m : Backend.Model
        m =
            ProgramTest.Config.replayInitStepsOntoModel ProgramTest.Config.demoWikiPagesPlusTwoPendingSubmissionsSteps
    in
    { m
        | contributorSessions =
            WikiUser.bindContributor sessionKey
                "Demo"
                (ContributorAccount.newAccountId "Demo" "trustedpub")
                m.contributorSessions
    }


updateTrusted : Time.Posix -> ToBackend -> Backend.Model -> Backend.Model
updateTrusted posix msg model =
    Tuple.first
        (Backend.updateFromFrontendWithTime
            (Effect.Lamdera.sessionIdFromString sessionKey)
            (Effect.Lamdera.clientIdFromString clientKey)
            msg
            posix
            model
        )


lastDemoEvent : Backend.Model -> Maybe WikiAuditLog.AuditEvent
lastDemoEvent model =
    model.wikiAuditEvents
        |> Dict.get "Demo"
        |> Maybe.andThen (\events -> List.head (List.reverse events))


expectActorTrustedModerator : WikiAuditLog.AuditEvent -> Expect.Expectation
expectActorTrustedModerator ev =
    ev.actorUsername
        |> Expect.equal "trustedpub"


suite : Test
suite =
    Test.describe "ModerationAudit"
        [ Test.describe "story 34 — backend moderation writes audit with moderator as actor"
            [ Test.test "ApproveSubmission appends ApprovedSubmission for trusted session user" <|
                \() ->
                    let
                        after : Backend.Model
                        after =
                            updateTrusted (Time.millisToPosix 0) (ApproveSubmission "Demo" "sub_1") trustedpubOnDemo
                    in
                    case lastDemoEvent after of
                        Nothing ->
                            Expect.fail "expected an audit event"

                        Just ev ->
                            Expect.all
                                [ expectActorTrustedModerator
                                , \e ->
                                    case e.kind of
                                        WikiAuditLog.ApprovedSubmission { submissionId, pageSlug } ->
                                            ( submissionId, pageSlug )
                                                |> Expect.equal ( "sub_1", "QueueDemoPage" )

                                        WikiAuditLog.RejectedSubmission _ ->
                                            Expect.fail "expected ApprovedSubmission"

                                        WikiAuditLog.RequestedSubmissionChanges _ ->
                                            Expect.fail "expected ApprovedSubmission"

                                        WikiAuditLog.PromotedContributorToTrusted _ ->
                                            Expect.fail "expected ApprovedSubmission"

                                        WikiAuditLog.DemotedTrustedToContributor _ ->
                                            Expect.fail "expected ApprovedSubmission"

                                        WikiAuditLog.GrantedWikiAdmin _ ->
                                            Expect.fail "expected ApprovedSubmission"

                                        WikiAuditLog.RevokedWikiAdmin _ ->
                                            Expect.fail "expected ApprovedSubmission"

                                        WikiAuditLog.TrustedPublishedNewPage _ ->
                                            Expect.fail "expected ApprovedSubmission"

                                        WikiAuditLog.TrustedPublishedPageEdit _ ->
                                            Expect.fail "expected ApprovedSubmission"

                                        WikiAuditLog.TrustedPublishedPageDelete _ ->
                                            Expect.fail "expected ApprovedSubmission"
                                ]
                                ev
            , Test.test "RejectSubmission appends RejectedSubmission with moderator username" <|
                \() ->
                    let
                        after : Backend.Model
                        after =
                            updateTrusted (Time.millisToPosix 0)
                                (RejectSubmission "Demo" { submissionId = "sub_1", reasonText = "blocked" })
                                trustedpubOnDemo
                    in
                    case lastDemoEvent after of
                        Nothing ->
                            Expect.fail "expected an audit event"

                        Just ev ->
                            Expect.all
                                [ expectActorTrustedModerator
                                , \e ->
                                    case e.kind of
                                        WikiAuditLog.RejectedSubmission { submissionId, pageSlug } ->
                                            ( submissionId, pageSlug )
                                                |> Expect.equal ( "sub_1", "QueueDemoPage" )

                                        WikiAuditLog.ApprovedSubmission _ ->
                                            Expect.fail "expected RejectedSubmission"

                                        WikiAuditLog.RequestedSubmissionChanges _ ->
                                            Expect.fail "expected RejectedSubmission"

                                        WikiAuditLog.PromotedContributorToTrusted _ ->
                                            Expect.fail "expected RejectedSubmission"

                                        WikiAuditLog.DemotedTrustedToContributor _ ->
                                            Expect.fail "expected RejectedSubmission"

                                        WikiAuditLog.GrantedWikiAdmin _ ->
                                            Expect.fail "expected RejectedSubmission"

                                        WikiAuditLog.RevokedWikiAdmin _ ->
                                            Expect.fail "expected RejectedSubmission"

                                        WikiAuditLog.TrustedPublishedNewPage _ ->
                                            Expect.fail "expected RejectedSubmission"

                                        WikiAuditLog.TrustedPublishedPageEdit _ ->
                                            Expect.fail "expected RejectedSubmission"

                                        WikiAuditLog.TrustedPublishedPageDelete _ ->
                                            Expect.fail "expected RejectedSubmission"
                                ]
                                ev
            , Test.test "RequestSubmissionChanges appends RequestedSubmissionChanges" <|
                \() ->
                    let
                        after : Backend.Model
                        after =
                            updateTrusted (Time.millisToPosix 0)
                                (RequestSubmissionChanges "Demo" { submissionId = "sub_2", guidanceText = "revise" })
                                trustedpubOnDemo
                    in
                    case lastDemoEvent after of
                        Nothing ->
                            Expect.fail "expected an audit event"

                        Just ev ->
                            Expect.all
                                [ expectActorTrustedModerator
                                , \e ->
                                    case e.kind of
                                        WikiAuditLog.RequestedSubmissionChanges { submissionId, pageSlug } ->
                                            ( submissionId, pageSlug )
                                                |> Expect.equal ( "sub_2", "RequestChangesDemoPage" )

                                        WikiAuditLog.ApprovedSubmission _ ->
                                            Expect.fail "expected RequestedSubmissionChanges"

                                        WikiAuditLog.RejectedSubmission _ ->
                                            Expect.fail "expected RequestedSubmissionChanges"

                                        WikiAuditLog.PromotedContributorToTrusted _ ->
                                            Expect.fail "expected RequestedSubmissionChanges"

                                        WikiAuditLog.DemotedTrustedToContributor _ ->
                                            Expect.fail "expected RequestedSubmissionChanges"

                                        WikiAuditLog.GrantedWikiAdmin _ ->
                                            Expect.fail "expected RequestedSubmissionChanges"

                                        WikiAuditLog.RevokedWikiAdmin _ ->
                                            Expect.fail "expected RequestedSubmissionChanges"

                                        WikiAuditLog.TrustedPublishedNewPage _ ->
                                            Expect.fail "expected RequestedSubmissionChanges"

                                        WikiAuditLog.TrustedPublishedPageEdit _ ->
                                            Expect.fail "expected RequestedSubmissionChanges"

                                        WikiAuditLog.TrustedPublishedPageDelete _ ->
                                            Expect.fail "expected RequestedSubmissionChanges"
                                ]
                                ev
            , Test.test "successive moderation audits use increasing timestamps when wall clock advances" <|
                \() ->
                    let
                        afterApprove : Backend.Model
                        afterApprove =
                            updateTrusted (Time.millisToPosix 1000) (ApproveSubmission "Demo" "sub_1") trustedpubOnDemo

                        afterBoth : Backend.Model
                        afterBoth =
                            updateTrusted (Time.millisToPosix 2000)
                                (RequestSubmissionChanges "Demo" { submissionId = "sub_2", guidanceText = "second" })
                                afterApprove

                        events : List WikiAuditLog.AuditEvent
                        events =
                            afterBoth.wikiAuditEvents
                                |> Dict.get "Demo"
                                |> Maybe.withDefault []

                        lastTwo : List WikiAuditLog.AuditEvent
                        lastTwo =
                            List.drop (List.length events - 2) events
                    in
                    case lastTwo of
                        [ e0, e1 ] ->
                            Time.posixToMillis e0.at
                                |> Expect.lessThan (Time.posixToMillis e1.at)

                        _ ->
                            Expect.fail
                                ("expected at least 2 audit events, got " ++ String.fromInt (List.length events))
            ]
        ]
