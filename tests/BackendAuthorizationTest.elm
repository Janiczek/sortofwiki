module BackendAuthorizationTest exposing (suite)

import Backend
import ContributorAccount
import Dict
import Effect.Lamdera
import Expect
import HostedWikiSlugPolicy
import Test exposing (Test)
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


withContributorSession : WikiUser.Binding -> Backend.Model -> Backend.Model
withContributorSession binding model =
    { model
        | contributorSessions =
            Dict.insert sessionKey binding model.contributorSessions
    }


statusdemoOnDemo : Backend.Model
statusdemoOnDemo =
    withContributorSession
        (WikiUser.Binding "demo" (ContributorAccount.newAccountId "demo" "statusdemo"))
        initialModel


trustedpubOnDemo : Backend.Model
trustedpubOnDemo =
    withContributorSession
        (WikiUser.Binding "demo" (ContributorAccount.newAccountId "demo" "trustedpub"))
        initialModel


expectUnchanged : Backend.Model -> ToBackend -> Expect.Expectation
expectUnchanged before msg =
    let
        ( after, _ ) =
            Backend.app_.updateFromFrontend
                (Effect.Lamdera.sessionIdFromString sessionKey)
                (Effect.Lamdera.clientIdFromString clientKey)
                msg
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
                    [ ( "RequestReviewQueue", RequestReviewQueue "demo" )
                    , ( "RequestReviewSubmissionDetail", RequestReviewSubmissionDetail "demo" "sub_queue_demo" )
                    , ( "RequestWikiUsers", RequestWikiUsers "demo" )
                    , ( "RequestWikiAuditLog", RequestWikiAuditLog "demo" WikiAuditLog.emptyAuditLogFilter )
                    , ( "PromoteContributorToTrusted", PromoteContributorToTrusted "demo" "x" )
                    , ( "DemoteTrustedToContributor", DemoteTrustedToContributor "demo" "x" )
                    , ( "GrantWikiAdmin", GrantWikiAdmin "demo" "x" )
                    , ( "RevokeWikiAdmin", RevokeWikiAdmin "demo" "x" )
                    , ( "RequestSubmissionDetails", RequestSubmissionDetails "demo" "sub_queue_demo" )
                    , ( "SubmitNewPage", SubmitNewPage "demo" "new-page" "## Body" )
                    , ( "SubmitPageEdit", SubmitPageEdit "demo" "home" "## Edit" )
                    , ( "SubmitPageDelete", SubmitPageDelete "demo" "home" "reason" )
                    , ( "ApproveSubmission", ApproveSubmission "demo" "sub_queue_demo" )
                    , ( "RejectSubmission", RejectSubmission "demo" "sub_queue_demo" "no" )
                    , ( "RequestSubmissionChanges", RequestSubmissionChanges "demo" "sub_queue_demo" "fix it" )
                    , ( "HostAdminLogin wrong password", HostAdminLogin "not-the-host-password" )
                    , ( "RequestHostWikiList", RequestHostWikiList )
                    , ( "RequestHostWikiDetail", RequestHostWikiDetail "demo" )
                    , ( "CreateHostedWiki", CreateHostedWiki "newwiki" "Name" )
                    , ( "UpdateHostedWikiMetadata"
                      , UpdateHostedWikiMetadata "demo" "N" "S" HostedWikiSlugPolicy.StrictSlugs
                      )
                    , ( "DeactivateHostedWiki", DeactivateHostedWiki "demo" )
                    , ( "ReactivateHostedWiki", ReactivateHostedWiki "demo" )
                    , ( "DeleteHostedWiki", DeleteHostedWiki "demo" "wrong" )
                    ]
                )
            , Test.describe "standard contributor on demo"
                [ Test.test "RequestReviewQueue returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (RequestReviewQueue "demo")
                , Test.test "RequestReviewSubmissionDetail returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (RequestReviewSubmissionDetail "demo" "sub_queue_demo")
                , Test.test "RequestWikiUsers returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (RequestWikiUsers "demo")
                , Test.test "RequestWikiAuditLog returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (RequestWikiAuditLog "demo" WikiAuditLog.emptyAuditLogFilter)
                , Test.test "ApproveSubmission returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (ApproveSubmission "demo" "sub_queue_demo")
                , Test.test "RejectSubmission returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (RejectSubmission "demo" "sub_queue_demo" "no")
                , Test.test "RequestSubmissionChanges returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (RequestSubmissionChanges "demo" "sub_queue_demo" "note")
                , Test.test "PromoteContributorToTrusted returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (PromoteContributorToTrusted "demo" "statusdemo")
                ]
            , Test.describe "trusted but not wiki admin"
                [ Test.test "RequestWikiUsers returns forbidden without changing model" <|
                    \() ->
                        expectUnchanged trustedpubOnDemo (RequestWikiUsers "demo")
                ]
            , Test.describe "session wiki does not match payload wiki"
                [ Test.test "SubmitNewPage to other wiki returns wrong session without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (SubmitNewPage "elm-tips" "p" "## x")
                , Test.test "RequestReviewQueue for other wiki returns wrong session without changing model" <|
                    \() ->
                        expectUnchanged statusdemoOnDemo (RequestReviewQueue "elm-tips")
                ]
            ]
        ]
