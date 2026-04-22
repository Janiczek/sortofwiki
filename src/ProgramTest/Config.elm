module ProgramTest.Config exposing
    ( ConfigBuilder
    , CreateWikiArgs
    , InitStep
    , demoWikiCatalogOnly
    , demoWikiModerationSteps
    , demoWikiPagesOnly
    , demoWikiPagesPlusTwoPendingSubmissionsSteps
    , demoWikiPagesSteps
    , demoWikiWithModerationSeeds
    , emptyConfig
    , replayInitStepsOntoModel
    )

import Backend
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Subscription exposing (Subscription)
import Effect.Test
import Env
import Frontend
import ProgramTest.Fixtures as Fixtures
import Time
import Types exposing (ToBackend(..), ToFrontend)
import Url exposing (Protocol(..), Url)


{-| Base URL for program-test (matches local `lamdera live`).
-}
unsafeDomainUrl : Url
unsafeDomainUrl =
    Url.fromString "http://localhost:8000"
        |> Maybe.withDefault
            { protocol = Http
            , host = "localhost"
            , port_ = Just 8000
            , path = ""
            , query = Nothing
            , fragment = Nothing
            }


{-| One Lamdera client turn: `Backend.app_.updateFromFrontend` with a synthetic session.
-}
type alias InitStep =
    { sessionKey : String
    , clientKey : String
    , msg : ToBackend
    }


initStep : String -> String -> ToBackend -> InitStep
initStep sessionKey clientKey msg =
    { sessionKey = sessionKey
    , clientKey = clientKey
    , msg = msg
    }


{-| Fold init steps onto `Tuple.first Backend.app_.init` (empty hosted catalog).
-}
replayInitStepsOntoModel : List InitStep -> Backend.Model
replayInitStepsOntoModel steps =
    let
        baseModel : Backend.Model
        baseModel =
            Tuple.first Backend.app_.init

        applyOne : InitStep -> ( Backend.Model, Int ) -> ( Backend.Model, Int )
        applyOne step ( model, clockMillis ) =
            ( Tuple.first
                (Backend.updateFromFrontendWithTime
                    (Effect.Lamdera.sessionIdFromString step.sessionKey)
                    (Effect.Lamdera.clientIdFromString step.clientKey)
                    step.msg
                    (Time.millisToPosix clockMillis)
                    model
                )
            , clockMillis + 1
            )
    in
    Tuple.first (List.foldl applyOne ( baseModel, 0 ) steps)


{-| Pipeline start: `finish (config |> createWiki … |> registerWikiUser …)`.
-}
type ConfigBuilder
    = ConfigBuilder (List InitStep)


finish : ConfigBuilder -> Effect.Test.Config ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
finish (ConfigBuilder steps) =
    let
        baseBackendApp :
            { init : ( Backend.Model, Command BackendOnly ToFrontend Backend.Msg )
            , update : Backend.Msg -> Backend.Model -> ( Backend.Model, Command BackendOnly ToFrontend Backend.Msg )
            , updateFromFrontend :
                SessionId
                -> ClientId
                -> ToBackend
                -> Backend.Model
                -> ( Backend.Model, Command BackendOnly ToFrontend Backend.Msg )
            , subscriptions : Backend.Model -> Subscription BackendOnly Backend.Msg
            }
        baseBackendApp =
            Backend.app_

        backendApp :
            { init : ( Backend.Model, Command BackendOnly ToFrontend Backend.Msg )
            , update : Backend.Msg -> Backend.Model -> ( Backend.Model, Command BackendOnly ToFrontend Backend.Msg )
            , updateFromFrontend :
                SessionId
                -> ClientId
                -> ToBackend
                -> Backend.Model
                -> ( Backend.Model, Command BackendOnly ToFrontend Backend.Msg )
            , subscriptions : Backend.Model -> Subscription BackendOnly Backend.Msg
            }
        backendApp =
            { baseBackendApp
                | init =
                    ( replayInitStepsOntoModel steps
                    , Command.none
                    )
            }
    in
    { frontendApp = Frontend.app_
    , backendApp = backendApp
    , handleHttpRequest = always Effect.Test.NetworkErrorResponse
    , handlePortToJs = always Nothing
    , handleFileUpload = always Effect.Test.UnhandledFileUpload
    , handleMultipleFilesUpload = always Effect.Test.UnhandledMultiFileUpload
    , domain = unsafeDomainUrl
    }


{-| Demo + ElmTips hosted wikis only (initial wiki admins exist); no contributor registrations or pages.
-}
demoWikiCatalogOnly : Effect.Test.Config ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
demoWikiCatalogOnly =
    finish <| ConfigBuilder demoWikiCatalogOnlySteps


{-| Host-admin creation of Demo and ElmTips (same slugs and wiki admins as the full program-test seed).
-}
demoWikiCatalogOnlySteps : List InitStep
demoWikiCatalogOnlySteps =
    List.concat
        [ hostAdminCreateWikiSteps
            { slug = "Demo"
            , name = "Demo Wiki"
            , wikiAdminUsername = "demo_wiki_admin"
            , wikiAdminPassword = "password12"
            }
        , hostAdminCreateWikiSteps
            { slug = "ElmTips"
            , name = "Elm Tips"
            , wikiAdminUsername = "elmtipsadmin"
            , wikiAdminPassword = "password12"
            }
        ]


{-| Register contributors, publish Demo + ElmTips pages (appends to `demoWikiCatalogOnlySteps`).
-}
demoWikiPagesSeedSteps : List InitStep
demoWikiPagesSeedSteps =
    [ initStep "pt-init-reg-demo_contributor" "pt-c1" (RegisterContributor "Demo" { username = "demo_contributor", password = "password12" })
    , initStep "pt-init-reg-demo_trusted_publisher" "pt-c2" (RegisterContributor "Demo" { username = "demo_trusted_publisher", password = "password12" })
    , initStep "pt-init-reg-grantadmin" "pt-c3" (RegisterContributor "Demo" { username = "grantadmin_trusted", password = "password12" })
    , initStep "pt-init-demo_wiki_admin-login" "pt-c4" (LoginContributor "Demo" { username = "demo_wiki_admin", password = "password12" })
    , initStep "pt-init-demo_wiki_admin-login" "pt-c4" (PromoteContributorToTrusted "Demo" "demo_trusted_publisher")
    , initStep "pt-init-demo_wiki_admin-login" "pt-c4" (PromoteContributorToTrusted "Demo" "grantadmin_trusted")
    , initStep "pt-init-demo_trusted_publisher-pub" "pt-c5" (LoginContributor "Demo" { username = "demo_trusted_publisher", password = "password12" })
    , initStep "pt-init-demo_trusted_publisher-pub" "pt-c5" (SubmitNewPage "Demo" { rawPageSlug = "Home", rawMarkdown = Fixtures.demoHomePublished, rawTags = "" })
    , initStep "pt-init-demo_trusted_publisher-pub" "pt-c5" (SubmitNewPage "Demo" { rawPageSlug = "Guides", rawMarkdown = Fixtures.demoGuidesPublished, rawTags = "" })
    , initStep "pt-init-demo_trusted_publisher-pub" "pt-c5" (SubmitNewPage "Demo" { rawPageSlug = "About", rawMarkdown = Fixtures.demoAboutPublished, rawTags = "" })
    , initStep "pt-init-demo_trusted_publisher-pub" "pt-c5" (SubmitNewPage "Demo" { rawPageSlug = "MarkdownPlayground", rawMarkdown = Fixtures.demoMarkdownPlaygroundPublished, rawTags = "" })
    , initStep "pt-init-demo_trusted_publisher-pub" "pt-c5" (SubmitNewPage "Demo" { rawPageSlug = "KitchenSink", rawMarkdown = Fixtures.demoKitchenSinkMarkdownPublished, rawTags = "" })
    , initStep "pt-init-elmtips-admin" "pt-c6" (LoginContributor "ElmTips" { username = "elmtipsadmin", password = "password12" })
    , initStep "pt-init-elmtips-admin" "pt-c6" (SubmitNewPage "ElmTips" { rawPageSlug = "Home", rawMarkdown = "Tips and notes about Elm.", rawTags = "" })
    ]


{-| `demoWikiCatalogOnlySteps` followed by `demoWikiPagesSeedSteps`.
-}
demoWikiPagesSteps : List InitStep
demoWikiPagesSteps =
    List.concat
        [ demoWikiCatalogOnlySteps
        , demoWikiPagesSeedSteps
        ]


{-| Program-test catalog: demo + elm-tips wikis, contributors, published pages; `nextSubmissionCounter` still 1.
-}
demoWikiPagesOnly : Effect.Test.Config ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
demoWikiPagesOnly =
    finish <| ConfigBuilder demoWikiPagesSteps


{-| Adds moderation submissions as `sub_1` … `sub_5` (same roles as former backend seed).
-}
demoWikiWithModerationSeeds : Effect.Test.Config ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
demoWikiWithModerationSeeds =
    finish <| ConfigBuilder demoWikiModerationSteps


{-| Empty hosted catalog (only `Backend.init` replay with no steps).
-}
emptyConfig : Effect.Test.Config ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
emptyConfig =
    finish <| ConfigBuilder []


story13RejectReason : String
story13RejectReason =
    "Seeded reviewer note: expand the outline and add sources before resubmitting."


{-| Demo + elm-tips + pages + `sub_1` / `sub_2` pending new-page submissions (no reject/approve yet).
-}
demoWikiPagesPlusTwoPendingSubmissionsSteps : List InitStep
demoWikiPagesPlusTwoPendingSubmissionsSteps =
    List.concat
        [ demoWikiPagesSteps
        , [ initStep "pt-mod2-demo_contributor" "pt-m2a" (LoginContributor "Demo" { username = "demo_contributor", password = "password12" })
          , initStep "pt-mod2-demo_contributor"
                "pt-m2a"
                (SubmitNewPage "Demo" { rawPageSlug = "QueueDemoPage", rawMarkdown = "Seeded pending submission for the trusted review queue.", rawTags = "" })
          , initStep "pt-mod2-demo_contributor"
                "pt-m2a"
                (SubmitNewPage "Demo" { rawPageSlug = "RequestChangesDemoPage", rawMarkdown = "Seeded pending submission for request-changes.", rawTags = "" })
          ]
        ]


demoWikiModerationSteps : List InitStep
demoWikiModerationSteps =
    List.concat
        [ demoWikiPagesSteps
        , [ initStep "pt-mod-demo_contributor" "pt-m1" (LoginContributor "Demo" { username = "demo_contributor", password = "password12" })
          , initStep "pt-mod-demo_contributor"
                "pt-m1"
                (SubmitNewPage "Demo" { rawPageSlug = "QueueDemoPage", rawMarkdown = "Seeded pending submission for the trusted review queue.", rawTags = "" })
          , initStep "pt-mod-demo_contributor"
                "pt-m1"
                (SubmitNewPage "Demo" { rawPageSlug = "RequestChangesDemoPage", rawMarkdown = "Seeded pending submission for request-changes.", rawTags = "" })
          , initStep "pt-mod-demo_contributor"
                "pt-m1"
                (SubmitNewPage "Demo" { rawPageSlug = "SeedRejected", rawMarkdown = "Seeded submission (rejected).", rawTags = "" })
          , initStep "pt-mod-demo_trusted_publisher" "pt-m2" (LoginContributor "Demo" { username = "demo_trusted_publisher", password = "password12" })
          , initStep "pt-mod-demo_trusted_publisher" "pt-m2" (RejectSubmission "Demo" { submissionId = "sub_3", reasonText = story13RejectReason })
          , initStep "pt-mod-demo_contributor" "pt-m3" (LoginContributor "Demo" { username = "demo_contributor", password = "password12" })
          , initStep "pt-mod-demo_contributor"
                "pt-m3"
                (SubmitPageEdit "Demo" "About" "Seeded submission (approved)." "")
          , initStep "pt-mod-demo_trusted_publisher" "pt-m4" (LoginContributor "Demo" { username = "demo_trusted_publisher", password = "password12" })
          , initStep "pt-mod-demo_trusted_publisher" "pt-m4" (ApproveSubmission "Demo" "sub_4")
          , initStep "pt-mod-demo_contributor" "pt-m5" (LoginContributor "Demo" { username = "demo_contributor", password = "password12" })
          , initStep "pt-mod-demo_contributor"
                "pt-m5"
                (RequestPublishedPageDeletion "Demo" "Guides" "Seeded delete request: page is redundant.")
          , initStep "pt-mod-demo_trusted_publisher" "pt-m6" (LoginContributor "Demo" { username = "demo_trusted_publisher", password = "password12" })
          , initStep "pt-mod-demo_trusted_publisher"
                "pt-m6"
                (RequestSubmissionChanges "Demo"
                    { submissionId = "sub_5"
                    , guidanceText = "Please justify why this page should be removed; deletion is disruptive."
                    }
                )
          ]
        ]


type alias CreateWikiArgs =
    { slug : String
    , name : String
    , wikiAdminUsername : String
    , wikiAdminPassword : String
    }


hostAdminCreateWikiSteps : CreateWikiArgs -> List InitStep
hostAdminCreateWikiSteps wiki =
    [ initStep "pt-host" "pt-host-c" (HostAdminLogin Env.hostAdminPassword)
    , initStep "pt-host"
        "pt-host-c"
        (CreateHostedWiki
            { rawSlug = wiki.slug
            , rawName = wiki.name
            , initialAdminUsername = wiki.wikiAdminUsername
            , initialAdminPassword = wiki.wikiAdminPassword
            }
        )
    ]
