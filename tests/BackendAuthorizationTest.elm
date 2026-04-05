module BackendAuthorizationTest exposing (suite)

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
    "backend-authz-test-session"


clientKey : String
clientKey =
    "backend-authz-test-client"


initialModel : Backend.Model
initialModel =
    Tuple.first Backend.app_.init


pagesFixture : Backend.Model
pagesFixture =
    ProgramTest.Config.replayInitStepsOntoModel ProgramTest.Config.demoWikiPagesSteps


moderationFixture : Backend.Model
moderationFixture =
    ProgramTest.Config.replayInitStepsOntoModel ProgramTest.Config.demoWikiModerationSteps


withContributorSession : String -> ContributorAccount.Id -> Backend.Model -> Backend.Model
withContributorSession wikiSlug accountId model =
    { model
        | contributorSessions =
            WikiUser.bindContributor sessionKey wikiSlug accountId model.contributorSessions
    }


demoContributorOnDemo : Backend.Model
demoContributorOnDemo =
    withContributorSession "Demo" (ContributorAccount.newAccountId "Demo" "demo_contributor") pagesFixture


demoTrustedPublisherOnDemo : Backend.Model
demoTrustedPublisherOnDemo =
    withContributorSession "Demo" (ContributorAccount.newAccountId "Demo" "demo_trusted_publisher") pagesFixture


demoContributorOnDemoModeration : Backend.Model
demoContributorOnDemoModeration =
    withContributorSession "Demo" (ContributorAccount.newAccountId "Demo" "demo_contributor") moderationFixture


demoTrustedPublisherOnDemoModeration : Backend.Model
demoTrustedPublisherOnDemoModeration =
    withContributorSession "Demo" (ContributorAccount.newAccountId "Demo" "demo_trusted_publisher") moderationFixture


{-| Demo wiki `active = False` (hosted wiki deactivated); contributor sessions unchanged.
-}
withDemoWikiInactive : Backend.Model -> Backend.Model
withDemoWikiInactive model =
    case Dict.get "Demo" model.wikis of
        Nothing ->
            model

        Just w ->
            { model | wikis = Dict.insert "Demo" { w | active = False } model.wikis }


expectUnchanged : Backend.Model -> ToBackend -> Expect.Expectation
expectUnchanged before msg =
    let
        ( after, _ ) =
            Backend.updateFromFrontendWithTime
                (Effect.Lamdera.sessionIdFromString sessionKey)
                (Effect.Lamdera.clientIdFromString clientKey)
                msg
                (Time.millisToPosix 0)
                before
    in
    after
        |> Expect.equal before


suite : Test
suite =
    Test.describe "Backend authorization (story 33)"
        [ Test.describe "updateFromFrontend"
            [ Test.describe "no contributor session leaves model unchanged on protected messages"
                (List.map
                    (\( label, msg ) ->
                        Test.test label <|
                            \() ->
                                expectUnchanged initialModel msg
                    )
                    [ ( "RequestMyPendingSubmissions", RequestMyPendingSubmissions "Demo" )
                    , ( "RequestReviewQueue", RequestReviewQueue "Demo" )
                    , ( "RequestReviewSubmissionDetail", RequestReviewSubmissionDetail "Demo" "sub_1" )
                    , ( "RequestWikiUsers", RequestWikiUsers "Demo" )
                    , ( "RequestWikiAuditLog", RequestWikiAuditLog "Demo" WikiAuditLog.emptyAuditLogFilter )
                    , ( "PromoteContributorToTrusted", PromoteContributorToTrusted "Demo" "x" )
                    , ( "DemoteTrustedToContributor", DemoteTrustedToContributor "Demo" "x" )
                    , ( "GrantWikiAdmin", GrantWikiAdmin "Demo" "x" )
                    , ( "RevokeWikiAdmin", RevokeWikiAdmin "Demo" "x" )
                    , ( "RequestSubmissionDetails", RequestSubmissionDetails "Demo" "sub_1" )
                    , ( "SubmitNewPage", SubmitNewPage "Demo" { rawPageSlug = "NewPage", rawMarkdown = "## Body" } )
                    , ( "SubmitPageEdit", SubmitPageEdit "Demo" "Home" "## Edit" )
                    , ( "RequestPublishedPageDeletion", RequestPublishedPageDeletion "Demo" "Home" "reason" )
                    , ( "DeletePublishedPageImmediately", DeletePublishedPageImmediately "Demo" "Home" "reason" )
                    , ( "ApproveSubmission", ApproveSubmission "Demo" "sub_1" )
                    , ( "RejectSubmission", RejectSubmission "Demo" { submissionId = "sub_1", reasonText = "no" } )
                    , ( "RequestSubmissionChanges", RequestSubmissionChanges "Demo" { submissionId = "sub_1", guidanceText = "fix it" } )
                    , ( "HostAdminLogin wrong password", HostAdminLogin "not-the-host-password" )
                    , ( "RequestHostWikiList", RequestHostWikiList )
                    , ( "RequestHostAuditLog", RequestHostAuditLog WikiAuditLog.emptyHostAuditLogFilter )
                    , ( "RequestHostWikiDetail", RequestHostWikiDetail "Demo" )
                    , ( "CreateHostedWiki"
                      , CreateHostedWiki
                            { rawSlug = "Newwiki"
                            , rawName = "Name"
                            , initialAdminUsername = "wikiadmin"
                            , initialAdminPassword = "password12"
                            }
                      )
                    , ( "UpdateHostedWikiMetadata"
                      , UpdateHostedWikiMetadata "Demo" { rawName = "N", rawSummary = "S", rawSlugDraft = "Demo" }
                      )
                    , ( "DeactivateHostedWiki", DeactivateHostedWiki "Demo" )
                    , ( "ReactivateHostedWiki", ReactivateHostedWiki "Demo" )
                    , ( "DeleteHostedWiki", DeleteHostedWiki "Demo" "wrong" )
                    , ( "RequestHostAdminDataExport", RequestHostAdminDataExport )
                    , ( "ImportHostAdminDataSnapshot", ImportHostAdminDataSnapshot "{}" )
                    , ( "RequestHostAdminWikiDataExport", RequestHostAdminWikiDataExport "Demo" )
                    , ( "ImportHostAdminWikiDataSnapshot", ImportHostAdminWikiDataSnapshot "Demo" "{}" )
                    ]
                )
            , Test.describe "standard contributor on demo"
                [ Test.test "RequestReviewQueue returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged demoContributorOnDemoModeration (RequestReviewQueue "Demo")
                , Test.test "RequestReviewSubmissionDetail returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged demoContributorOnDemoModeration (RequestReviewSubmissionDetail "Demo" "sub_1")
                , Test.test "RequestWikiUsers returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged demoContributorOnDemo (RequestWikiUsers "Demo")
                , Test.test "RequestWikiAuditLog returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged demoContributorOnDemo (RequestWikiAuditLog "Demo" WikiAuditLog.emptyAuditLogFilter)
                , Test.test "RequestHostAuditLog leaves model unchanged without host session" <|
                    \() ->
                        expectUnchanged demoContributorOnDemo (RequestHostAuditLog WikiAuditLog.emptyHostAuditLogFilter)
                , Test.test "ApproveSubmission returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged demoContributorOnDemoModeration (ApproveSubmission "Demo" "sub_1")
                , Test.test "RejectSubmission returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged demoContributorOnDemoModeration (RejectSubmission "Demo" { submissionId = "sub_1", reasonText = "no" })
                , Test.test "RequestSubmissionChanges returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged demoContributorOnDemoModeration (RequestSubmissionChanges "Demo" { submissionId = "sub_1", guidanceText = "note" })
                , Test.test "PromoteContributorToTrusted returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged demoContributorOnDemo (PromoteContributorToTrusted "Demo" "demo_contributor")
                ]
            , Test.describe "trusted but not wiki admin"
                [ Test.test "RequestWikiUsers returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged demoTrustedPublisherOnDemo (RequestWikiUsers "Demo")
                , Test.test "RequestMyPendingSubmissions returns forbidden for trusted moderator without changing model" <|
                    \() ->
                        expectUnchanged demoTrustedPublisherOnDemo (RequestMyPendingSubmissions "Demo")
                ]
            , Test.describe "session wiki does not match payload wiki"
                [ Test.test "SubmitNewPage to other wiki returns wrong session without changing model" <|
                    \() ->
                        expectUnchanged demoContributorOnDemo (SubmitNewPage "ElmTips" { rawPageSlug = "P", rawMarkdown = "## x" })
                , Test.test "RequestReviewQueue for other wiki returns wrong session without changing model" <|
                    \() ->
                        expectUnchanged demoContributorOnDemo (RequestReviewQueue "ElmTips")
                , Test.test "RequestMyPendingSubmissions for other wiki returns wrong session without changing model" <|
                    \() ->
                        expectUnchanged demoContributorOnDemo (RequestMyPendingSubmissions "ElmTips")
                ]
            , Test.describe "inactive demo wiki (deactivated tenant)"
                [ Test.test "trusted RequestReviewQueue leaves model unchanged" <|
                    \() ->
                        demoTrustedPublisherOnDemoModeration
                            |> withDemoWikiInactive
                            |> (\m -> expectUnchanged m (RequestReviewQueue "Demo"))
                , Test.test "contributor SubmitNewPage leaves model unchanged" <|
                    \() ->
                        demoContributorOnDemo
                            |> withDemoWikiInactive
                            |> (\m -> expectUnchanged m (SubmitNewPage "Demo" { rawPageSlug = "NewPage", rawMarkdown = "## Body" }))
                , Test.test "trusted ApproveSubmission leaves model unchanged" <|
                    \() ->
                        demoTrustedPublisherOnDemoModeration
                            |> withDemoWikiInactive
                            |> (\m -> expectUnchanged m (ApproveSubmission "Demo" "sub_1"))
                , Test.test "contributor RequestMyPendingSubmissions leaves model unchanged" <|
                    \() ->
                        demoContributorOnDemo
                            |> withDemoWikiInactive
                            |> (\m -> expectUnchanged m (RequestMyPendingSubmissions "Demo"))
                ]
            , Test.describe "logout"
                [ Test.test "LogoutContributor with no session leaves contributorSessions empty" <|
                    \() ->
                        expectUnchanged initialModel (LogoutContributor "Demo")
                , Test.test "LogoutContributor clears bound contributor session for that wiki" <|
                    \() ->
                        let
                            ( after, _ ) =
                                Backend.updateFromFrontendWithTime
                                    (Effect.Lamdera.sessionIdFromString sessionKey)
                                    (Effect.Lamdera.clientIdFromString clientKey)
                                    (LogoutContributor "Demo")
                                    (Time.millisToPosix 0)
                                    demoContributorOnDemo
                        in
                        after.contributorSessions
                            |> Dict.get sessionKey
                            |> Expect.equal Nothing
                , Test.test "LogoutContributor removes only the given wiki when multiple are bound" <|
                    \() ->
                        let
                            demoId : ContributorAccount.Id
                            demoId =
                                ContributorAccount.newAccountId "Demo" "demo_contributor"

                            elmId : ContributorAccount.Id
                            elmId =
                                ContributorAccount.newAccountId "ElmTips" "elmtipsadmin"

                            multi : Backend.Model
                            multi =
                                pagesFixture
                                    |> withContributorSession "Demo" demoId
                                    |> withContributorSession "ElmTips" elmId

                            ( after, _ ) =
                                Backend.updateFromFrontendWithTime
                                    (Effect.Lamdera.sessionIdFromString sessionKey)
                                    (Effect.Lamdera.clientIdFromString clientKey)
                                    (LogoutContributor "Demo")
                                    (Time.millisToPosix 0)
                                    multi
                        in
                        after.contributorSessions
                            |> Dict.get sessionKey
                            |> Expect.equal (Just (Dict.singleton "ElmTips" elmId))
                ]
            ]
        ]
