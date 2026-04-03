module ProgramTest.Config exposing
    ( ConfigBuilder
    , CreateWikiArgs
    , InitStep
    , demoWikiModerationSteps
    , demoWikiPagesOnly
    , demoWikiPagesPlusTwoPendingSubmissionsSteps
    , demoWikiPagesSteps
    , demoWikiWithModerationSeeds
    , emptyConfig
    , replayInitStepsOntoModel
    )

import Backend
import Effect.Command as Command
import Effect.Lamdera
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
        baseBackendApp =
            Backend.app_

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


demoWikiPagesSteps : List InitStep
demoWikiPagesSteps =
    List.concat
        [ hostAdminCreateWikiSteps
            { slug = "Demo"
            , name = "Demo Wiki"
            , wikiAdminUsername = "wikidemo"
            , wikiAdminPassword = "password12"
            }
        , hostAdminCreateWikiSteps
            { slug = "ElmTips"
            , name = "Elm Tips"
            , wikiAdminUsername = "elmtipsadmin"
            , wikiAdminPassword = "password12"
            }
        , [ initStep "pt-init-reg-statusdemo" "pt-c1" (RegisterContributor "Demo" { username = "statusdemo", password = "password12" })
          , initStep "pt-init-reg-trustedpub" "pt-c2" (RegisterContributor "Demo" { username = "trustedpub", password = "password12" })
          , initStep "pt-init-reg-grantadmin" "pt-c3" (RegisterContributor "Demo" { username = "grantadmin_trusted", password = "password12" })
          , initStep "pt-init-wikidemo-login" "pt-c4" (LoginContributor "Demo" { username = "wikidemo", password = "password12" })
          , initStep "pt-init-wikidemo-login" "pt-c4" (PromoteContributorToTrusted "Demo" "trustedpub")
          , initStep "pt-init-wikidemo-login" "pt-c4" (PromoteContributorToTrusted "Demo" "grantadmin_trusted")
          , initStep "pt-init-trustedpub-pub" "pt-c5" (LoginContributor "Demo" { username = "trustedpub", password = "password12" })
          , initStep "pt-init-trustedpub-pub" "pt-c5" (SubmitNewPage "Demo" { rawPageSlug = "Home", rawMarkdown = Fixtures.demoHomePublished })
          , initStep "pt-init-trustedpub-pub" "pt-c5" (SubmitNewPage "Demo" { rawPageSlug = "Guides", rawMarkdown = Fixtures.demoGuidesPublished })
          , initStep "pt-init-trustedpub-pub" "pt-c5" (SubmitNewPage "Demo" { rawPageSlug = "About", rawMarkdown = Fixtures.demoAboutPublished })
          , initStep "pt-init-trustedpub-pub" "pt-c5" (SubmitNewPage "Demo" { rawPageSlug = "MarkdownPlayground", rawMarkdown = Fixtures.demoMarkdownPlaygroundPublished })
          , initStep "pt-init-elmtips-admin" "pt-c6" (LoginContributor "ElmTips" { username = "elmtipsadmin", password = "password12" })
          , initStep "pt-init-elmtips-admin" "pt-c6" (SubmitNewPage "ElmTips" { rawPageSlug = "Home", rawMarkdown = "Tips and notes about Elm." })
          ]
        ]


story13RejectReason : String
story13RejectReason =
    "Seeded reviewer note (story 13): expand the outline and add sources before resubmitting."


{-| Demo + elm-tips + pages + `sub_1` / `sub_2` pending new-page submissions (no reject/approve yet).
-}
demoWikiPagesPlusTwoPendingSubmissionsSteps : List InitStep
demoWikiPagesPlusTwoPendingSubmissionsSteps =
    List.concat
        [ demoWikiPagesSteps
        , [ initStep "pt-mod2-statusdemo" "pt-m2a" (LoginContributor "Demo" { username = "statusdemo", password = "password12" })
          , initStep "pt-mod2-statusdemo"
                "pt-m2a"
                (SubmitNewPage "Demo" { rawPageSlug = "QueueDemoPage", rawMarkdown = "Seeded pending submission for the trusted review queue (story 15)." })
          , initStep "pt-mod2-statusdemo"
                "pt-m2a"
                (SubmitNewPage "Demo" { rawPageSlug = "RequestChangesDemoPage", rawMarkdown = "Seeded pending submission for request-changes (story 19)." })
          ]
        ]


demoWikiModerationSteps : List InitStep
demoWikiModerationSteps =
    List.concat
        [ demoWikiPagesSteps
        , [ initStep "pt-mod-statusdemo" "pt-m1" (LoginContributor "Demo" { username = "statusdemo", password = "password12" })
          , initStep "pt-mod-statusdemo"
                "pt-m1"
                (SubmitNewPage "Demo" { rawPageSlug = "QueueDemoPage", rawMarkdown = "Seeded pending submission for the trusted review queue (story 15)." })
          , initStep "pt-mod-statusdemo"
                "pt-m1"
                (SubmitNewPage "Demo" { rawPageSlug = "RequestChangesDemoPage", rawMarkdown = "Seeded pending submission for request-changes (story 19)." })
          , initStep "pt-mod-statusdemo"
                "pt-m1"
                (SubmitNewPage "Demo" { rawPageSlug = "SeedRejected", rawMarkdown = "Seeded submission (rejected)." })
          , initStep "pt-mod-trustedpub" "pt-m2" (LoginContributor "Demo" { username = "trustedpub", password = "password12" })
          , initStep "pt-mod-trustedpub" "pt-m2" (RejectSubmission "Demo" { submissionId = "sub_3", reasonText = story13RejectReason })
          , initStep "pt-mod-statusdemo" "pt-m3" (LoginContributor "Demo" { username = "statusdemo", password = "password12" })
          , initStep "pt-mod-statusdemo"
                "pt-m3"
                (SubmitPageEdit "Demo" "About" "Seeded submission (approved).")
          , initStep "pt-mod-trustedpub" "pt-m4" (LoginContributor "Demo" { username = "trustedpub", password = "password12" })
          , initStep "pt-mod-trustedpub" "pt-m4" (ApproveSubmission "Demo" "sub_4")
          , initStep "pt-mod-statusdemo" "pt-m5" (LoginContributor "Demo" { username = "statusdemo", password = "password12" })
          , initStep "pt-mod-statusdemo" "pt-m5" (SubmitPageDelete "Demo" "Guides" "")
          , initStep "pt-mod-trustedpub" "pt-m6" (LoginContributor "Demo" { username = "trustedpub", password = "password12" })
          , initStep "pt-mod-trustedpub"
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
