module ModerationAuditTest exposing (suite)

import Backend
import ContributorAccount
import Dict
import Effect.Lamdera
import Expect
import Test exposing (Test)
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
            Tuple.first Backend.app_.init
    in
    { m
        | contributorSessions =
            Dict.insert sessionKey
                (WikiUser.Binding "demo" (ContributorAccount.newAccountId "demo" "trustedpub"))
                m.contributorSessions
    }


updateTrusted : ToBackend -> Backend.Model -> Backend.Model
updateTrusted msg model =
    Tuple.first
        (Backend.app_.updateFromFrontend
            (Effect.Lamdera.sessionIdFromString sessionKey)
            (Effect.Lamdera.clientIdFromString clientKey)
            msg
            model
        )


lastDemoEvent : Backend.Model -> Maybe WikiAuditLog.AuditEvent
lastDemoEvent model =
    model.wikiAuditEvents
        |> Dict.get "demo"
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
                            updateTrusted (ApproveSubmission "demo" "sub_queue_demo") trustedpubOnDemo
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
                                            Expect.equal ( submissionId, pageSlug )
                                                ( "sub_queue_demo", "queue-demo-page" )

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
                            updateTrusted
                                (RejectSubmission "demo" "sub_queue_demo" "blocked")
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
                                            Expect.equal ( submissionId, pageSlug )
                                                ( "sub_queue_demo", "queue-demo-page" )

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
                            updateTrusted
                                (RequestSubmissionChanges "demo" "sub_changes_demo" "revise")
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
                                            Expect.equal ( submissionId, pageSlug )
                                                ( "sub_changes_demo", "request-changes-demo-page" )

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
            , Test.test "successive moderation audits use increasing atMillis (auditClockMillis)" <|
                \() ->
                    let
                        afterApprove : Backend.Model
                        afterApprove =
                            updateTrusted (ApproveSubmission "demo" "sub_queue_demo") trustedpubOnDemo

                        afterBoth : Backend.Model
                        afterBoth =
                            updateTrusted
                                (RequestSubmissionChanges "demo" "sub_changes_demo" "second")
                                afterApprove

                        events : List WikiAuditLog.AuditEvent
                        events =
                            afterBoth.wikiAuditEvents
                                |> Dict.get "demo"
                                |> Maybe.withDefault []
                    in
                    case events of
                        [ e0, e1 ] ->
                            e0.atMillis
                                |> Expect.lessThan e1.atMillis

                        _ ->
                            Expect.fail ("expected exactly 2 audit events, got " ++ String.fromInt (List.length events))
            ]
        ]
