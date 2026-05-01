module BackendWikiSearchTest exposing (suite)

import Backend
import BackendDataExport
import ContributorAccount
import Dict
import Effect.Lamdera
import Expect
import Page
import ProgramTest.Config
import Set
import Test exposing (Test)
import Time
import Types exposing (ToBackend(..), ToFrontend(..))
import Wiki
import WikiUser
import WikiSearch


sessionKey : String
sessionKey =
    "backend-wiki-search-session"


clientKey : String
clientKey =
    "backend-wiki-search-client"


survivalMarkdown : String
survivalMarkdown =
    "# Survival (skill)\n\n* [[Insight|insight]] when in conversation or examining an area or an object"


staleIndex : WikiSearch.PrefixIndex
staleIndex =
    Dict.fromList
        [ ( "zzz"
          , Dict.fromList
                [ ( "Unrelated", 1 )
                ]
          )
        ]


demoWikiWithSurvivalPage : Wiki.Wiki
demoWikiWithSurvivalPage =
    Wiki.wikiWithPages
        "Demo"
        "Demo"
        (Dict.fromList
            [ ( "SurvivalSkill", Page.withPublished "SurvivalSkill" survivalMarkdown )
            ]
        )


modelWithStaleSearchIndex : Backend.Model
modelWithStaleSearchIndex =
    let
        base : Backend.Model
        base =
            Tuple.first Backend.app_.init
    in
    { base
        | wikis = Dict.fromList [ ( "Demo", demoWikiWithSurvivalPage ) ]
        , wikiSearchIndexes = Dict.fromList [ ( "Demo", staleIndex ) ]
    }


{-| Wiki has pages but `wikiSearchIndexes` has no entry (e.g. after migration cleared cache).
-}
modelWithMissingSearchIndex : Backend.Model
modelWithMissingSearchIndex =
    let
        base : Backend.Model
        base =
            Tuple.first Backend.app_.init
    in
    { base
        | wikis = Dict.fromList [ ( "Demo", demoWikiWithSurvivalPage ) ]
        , wikiSearchIndexes = Dict.empty
    }


expectedInsightResults : List WikiSearch.ResultItem
expectedInsightResults =
    demoWikiWithSurvivalPage
        |> Wiki.frontendDetails
        |> .publishedPageMarkdownSources
        |> WikiSearch.buildPrefixIndex
        |> WikiSearch.searchWithPrefixIndex "insight"


pagesFixture : Backend.Model
pagesFixture =
    ProgramTest.Config.replayInitStepsOntoModel ProgramTest.Config.demoWikiPagesSteps


withContributorSession : String -> ContributorAccount.Id -> Backend.Model -> Backend.Model
withContributorSession wikiSlug accountId model =
    { model
        | contributorSessions =
            WikiUser.bindContributor sessionKey wikiSlug accountId model.contributorSessions
    }


searchResultSlugs : Wiki.Slug -> String -> Backend.Model -> List String
searchResultSlugs wikiSlug query model =
    model.wikiSearchIndexes
        |> Dict.get wikiSlug
        |> Maybe.withDefault Dict.empty
        |> WikiSearch.searchWithPrefixIndex query
        |> List.map .pageSlug


clientId : Effect.Lamdera.ClientId
clientId =
    Effect.Lamdera.clientIdFromString clientKey


trustedPublisherOnDemo : Backend.Model
trustedPublisherOnDemo =
    pagesFixture
        |> withContributorSession
            "Demo"
            (ContributorAccount.newAccountId "Demo" "demo_trusted_publisher")


suite : Test
suite =
    Test.describe "Backend wiki search"
        [ Test.test "RequestWikiSearch uses cached index" <|
            \() ->
                let
                    ( _, cmd ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (RequestWikiSearch "Demo" "insight")
                            (Time.millisToPosix 0)
                            modelWithStaleSearchIndex
                in
                cmd
                    |> Expect.equal
                        (Effect.Lamdera.sendToFrontend
                            clientId
                            (WikiSearchResponse "Demo" "insight" [])
                        )
        , Test.test "RequestWikiSearch rebuilds index when cache entry missing" <|
            \() ->
                let
                    ( after, cmd ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (RequestWikiSearch "Demo" "insight")
                            (Time.millisToPosix 0)
                            modelWithMissingSearchIndex
                in
                Expect.all
                    [ \_ ->
                        cmd
                            |> Expect.equal
                                (Effect.Lamdera.sendToFrontend
                                    clientId
                                    (WikiSearchResponse "Demo" "insight" expectedInsightResults)
                                )
                    , \_ ->
                        after
                            |> searchResultSlugs "Demo" "insight"
                            |> Expect.equal [ "SurvivalSkill" ]
                    , \_ ->
                        Dict.get "Demo" after.wikiSearchIndexes
                            |> Maybe.map (WikiSearch.searchWithPrefixIndex "insight" >> List.map .pageSlug)
                            |> Expect.equal (Just [ "SurvivalSkill" ])
                    ]
                    ()
        , Test.test "trusted SubmitNewPage rebuilds and stores cached index" <|
            \() ->
                let
                    ( after, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (SubmitNewPage
                                "Demo"
                                { rawPageSlug = "SearchCacheNewPage"
                                , rawMarkdown = "cachetermnew"
                                , rawTags = ""
                                }
                            )
                            (Time.millisToPosix 0)
                            trustedPublisherOnDemo
                in
                after
                    |> searchResultSlugs "Demo" "cachetermnew"
                    |> Expect.equal [ "SearchCacheNewPage" ]
        , Test.test "trusted SubmitPageEdit rebuilds and stores cached index" <|
            \() ->
                let
                    ( after, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (SubmitPageEdit "Demo" "Home" "## Home\n\ncachetermedit" "")
                            (Time.millisToPosix 0)
                            trustedPublisherOnDemo
                in
                after
                    |> searchResultSlugs "Demo" "cachetermedit"
                    |> Expect.equal [ "Home" ]
        , Test.test "trusted DeletePublishedPageImmediately rebuilds cached index" <|
            \() ->
                let
                    ( afterCreate, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (SubmitNewPage
                                "Demo"
                                { rawPageSlug = "SearchCacheDeletePage"
                                , rawMarkdown = "cachetermdelete"
                                , rawTags = ""
                                }
                            )
                            (Time.millisToPosix 0)
                            trustedPublisherOnDemo

                    ( afterDelete, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (DeletePublishedPageImmediately "Demo" "SearchCacheDeletePage" "cleanup")
                            (Time.millisToPosix 0)
                            afterCreate
                in
                afterDelete
                    |> searchResultSlugs "Demo" "cachetermdelete"
                    |> Expect.equal []
        , Test.test "ImportHostAdminWikiDataSnapshot rebuilds and stores cached index" <|
            \() ->
                let
                    snapshotJson : String
                    snapshotJson =
                        BackendDataExport.encodeWikiSnapshotToJsonString "Demo"
                            { modelWithStaleSearchIndex | wikiSearchIndexes = Dict.empty }
                            |> Maybe.withDefault ""

                    targetModel : Backend.Model
                    targetModel =
                        let
                            base : Backend.Model
                            base =
                                Tuple.first Backend.app_.init

                            targetWiki : Wiki.Wiki
                            targetWiki =
                                Wiki.wikiWithPages
                                    "Demo"
                                    "Demo"
                                    (Dict.fromList
                                        [ ( "Home", Page.withPublished "Home" "# Home\n\nno insight here" )
                                        ]
                                    )
                        in
                        { base
                            | wikis = Dict.fromList [ ( "Demo", targetWiki ) ]
                            , wikiSearchIndexes = Dict.fromList [ ( "Demo", staleIndex ) ]
                            , hostSessions = Set.fromList [ sessionKey ]
                        }

                    ( after, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (ImportHostAdminWikiDataSnapshot "Demo" snapshotJson)
                            (Time.millisToPosix 0)
                            targetModel
                in
                after
                    |> searchResultSlugs "Demo" "insight"
                    |> Expect.equal [ "SurvivalSkill" ]
        , Test.test "ImportHostAdminWikiDataSnapshotAuto rebuilds and stores cached index" <|
            \() ->
                let
                    snapshotJson : String
                    snapshotJson =
                        BackendDataExport.encodeWikiSnapshotToJsonString "Demo"
                            { modelWithStaleSearchIndex | wikiSearchIndexes = Dict.empty }
                            |> Maybe.withDefault ""

                    targetModel : Backend.Model
                    targetModel =
                        let
                            base : Backend.Model
                            base =
                                Tuple.first Backend.app_.init
                        in
                        { base
                            | wikiSearchIndexes = Dict.singleton "Demo" staleIndex
                            , hostSessions = Set.fromList [ sessionKey ]
                        }

                    ( after, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (ImportHostAdminWikiDataSnapshotAuto snapshotJson)
                            (Time.millisToPosix 0)
                            targetModel
                in
                after
                    |> searchResultSlugs "Demo" "insight"
                    |> Expect.equal [ "SurvivalSkill" ]
        , Test.test "ApproveSubmission rebuilds and stores cached index" <|
            \() ->
                let
                    contributorModel : Backend.Model
                    contributorModel =
                        pagesFixture
                            |> withContributorSession
                                "Demo"
                                (ContributorAccount.newAccountId "Demo" "demo_contributor")

                    ( withPendingSubmission, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (SubmitNewPage
                                "Demo"
                                { rawPageSlug = "SearchCacheApprovedPage"
                                , rawMarkdown = "cachetermapproved"
                                , rawTags = ""
                                }
                            )
                            (Time.millisToPosix 0)
                            contributorModel

                    trustedApproverModel : Backend.Model
                    trustedApproverModel =
                        withPendingSubmission
                            |> withContributorSession
                                "Demo"
                                (ContributorAccount.newAccountId "Demo" "demo_trusted_publisher")

                    ( afterApprove, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (ApproveSubmission "Demo" "sub_1")
                            (Time.millisToPosix 0)
                            trustedApproverModel
                in
                afterApprove
                    |> searchResultSlugs "Demo" "cachetermapproved"
                    |> Expect.equal [ "SearchCacheApprovedPage" ]
        , Test.test "UpdateHostedWikiMetadata slug rename keeps cached index under new slug" <|
            \() ->
                let
                    model : Backend.Model
                    model =
                        { modelWithStaleSearchIndex
                            | hostSessions = Set.fromList [ sessionKey ]
                        }

                    ( after, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (UpdateHostedWikiMetadata
                                "Demo"
                                { rawName = "Demo"
                                , rawSummary = ""
                                , rawSlugDraft = "DemoRenamed"
                                }
                            )
                            (Time.millisToPosix 0)
                            model
                in
                after
                    |> searchResultSlugs "DemoRenamed" "insight"
                    |> Expect.equal [ "SurvivalSkill" ]
        , Test.test "DeleteHostedWiki removes cached index" <|
            \() ->
                let
                    model : Backend.Model
                    model =
                        { modelWithStaleSearchIndex
                            | hostSessions = Set.fromList [ sessionKey ]
                        }

                    ( after, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (DeleteHostedWiki "Demo" "Demo")
                            (Time.millisToPosix 0)
                            model
                in
                Dict.get "Demo" after.wikiSearchIndexes
                    |> Expect.equal Nothing
        , Test.test "Deactivate/reactivate hosted wiki keeps cached index in sync" <|
            \() ->
                let
                    model : Backend.Model
                    model =
                        { modelWithStaleSearchIndex
                            | hostSessions = Set.fromList [ sessionKey ]
                        }

                    ( afterDeactivate, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (DeactivateHostedWiki "Demo")
                            (Time.millisToPosix 0)
                            model

                    ( afterReactivate, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (ReactivateHostedWiki "Demo")
                            (Time.millisToPosix 0)
                            afterDeactivate
                in
                afterReactivate
                    |> searchResultSlugs "Demo" "insight"
                    |> Expect.equal [ "SurvivalSkill" ]
        , Test.test "Host import full snapshot rebuilds all cached indexes" <|
            \() ->
                let
                    snapshotJson : String
                    snapshotJson =
                        BackendDataExport.encodeModelToJsonString
                            { modelWithStaleSearchIndex | wikiSearchIndexes = Dict.empty }

                    targetModel : Backend.Model
                    targetModel =
                        let
                            base : Backend.Model
                            base =
                                Tuple.first Backend.app_.init
                        in
                        { base | hostSessions = Set.fromList [ sessionKey ] }

                    ( after, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (ImportHostAdminDataSnapshot snapshotJson)
                            (Time.millisToPosix 0)
                            targetModel
                in
                after
                    |> searchResultSlugs "Demo" "insight"
                    |> Expect.equal [ "SurvivalSkill" ]
        , Test.test "CreateHostedWiki builds and stores cached index for new wiki" <|
            \() ->
                let
                    model : Backend.Model
                    model =
                        let
                            base : Backend.Model
                            base =
                                Tuple.first Backend.app_.init
                        in
                        { base | hostSessions = Set.fromList [ sessionKey ] }

                    ( after, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (CreateHostedWiki
                                { rawSlug = "Newcachewiki"
                                , rawName = "New cache wiki"
                                , initialAdminUsername = "cache_admin"
                                , initialAdminPassword = "password12"
                                }
                            )
                            (Time.millisToPosix 0)
                            model
                in
                Dict.get "Newcachewiki" after.wikiSearchIndexes
                    |> Expect.equal (Just Dict.empty)
        , Test.test "trusted DeletePublishedPageImmediately removes hit used by RequestWikiSearch" <|
            \() ->
                let
                    ( afterCreate, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (SubmitNewPage
                                "Demo"
                                { rawPageSlug = "SearchCacheDeleteRoundTrip"
                                , rawMarkdown = "cachetermroundtrip"
                                , rawTags = ""
                                }
                            )
                            (Time.millisToPosix 0)
                            trustedPublisherOnDemo

                    ( afterDelete, _ ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (DeletePublishedPageImmediately "Demo" "SearchCacheDeleteRoundTrip" "cleanup")
                            (Time.millisToPosix 0)
                            afterCreate

                    ( _, cmd ) =
                        Backend.updateFromFrontendWithTime
                            (Effect.Lamdera.sessionIdFromString sessionKey)
                            clientId
                            (RequestWikiSearch "Demo" "cachetermroundtrip")
                            (Time.millisToPosix 0)
                            afterDelete
                in
                cmd
                    |> Expect.equal
                        (Effect.Lamdera.sendToFrontend
                            clientId
                            (WikiSearchResponse "Demo" "cachetermroundtrip" [])
                        )
        ]
