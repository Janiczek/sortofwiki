module ProgramTest.Story29_CreateHostedWiki exposing (endToEndTests)

import Effect.Browser.Dom
import Env
import HostAdmin
import Json.Encode
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Submission
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


story29WikiLoginUrl : Url
story29WikiLoginUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Story29Wiki/login"
    , query = Nothing
    , fragment = Nothing
    }


invalidWikiSlugUserMessage : String
invalidWikiSlugUserMessage =
    HostAdmin.CreateSlugInvalid Submission.SlugInvalidChars
        |> HostAdmin.createHostedWikiErrorToUserText


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "Create a wiki"
        , config = ProgramTest.Config.emptyConfig
        , sessionId = "session-story29-create-wiki"
        , path = "/admin"
        , connectClientMs = Just 200
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "host-admin-login-form" client
                    , [ client.checkView 300
                            (ProgramTest.Query.withinId "host-admin-wikis-list"
                                (ProgramTest.Query.expectHasText "No wikis present")
                            )
                      , client.clickLink 100 Wiki.hostAdminNewWikiUrlPath
                      , client.checkView 200
                            (ProgramTest.Query.withinId "host-admin-create-wiki-page"
                                ProgramTest.Query.expectEmpty
                            )
                      , client.checkView 200
                            (ProgramTest.Query.withinId "host-admin-create-wiki-page"
                                ProgramTest.Query.expectHostAdminCreateWikiSlugInputUsesHtmlConstraints
                            )
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-slug") "Story29Wiki"
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-name") "Story 29 Wiki"
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-initial-admin-username") "story29admin"
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-initial-admin-password") "password12"
                      , client.custom 100 (Effect.Browser.Dom.id "host-admin-create-wiki-form") "submit" (Json.Encode.object [])
                      , client.checkView 400
                            (ProgramTest.Query.withinHostAdminWikiRow "Story29Wiki"
                                (ProgramTest.Query.expectHasText "Story 29 Wiki")
                            )
                      , client.update 100 (UrlChanged story29WikiLoginUrl)
                      , client.checkView 300
                            (ProgramTest.Query.expectWikiLoginPageShowsSlug "Story29Wiki")
                      ]
                    , ProgramTest.Actions.submitWikiLoginForm
                        { username = "story29admin"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.expectPageShowsWikiSlug "wiki-home-page" "Story29Wiki"
                                , ProgramTest.Query.withinId "wiki-home-page"
                                    (ProgramTest.Query.expectHasText "No pages yet")
                                ]
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "Create a wiki - reject non-PascalCase slug"
        , config = ProgramTest.Config.emptyConfig
        , sessionId = "session-story29-create-wiki-invalid-slug"
        , path = "/admin"
        , connectClientMs = Just 200
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "host-admin-login-form" client
                    , [ client.checkView 300
                            (ProgramTest.Query.withinId "host-admin-wikis-list"
                                (ProgramTest.Query.expectHasText "No wikis present")
                            )
                      , client.clickLink 100 Wiki.hostAdminNewWikiUrlPath
                      , client.checkView 200
                            (ProgramTest.Query.withinId "host-admin-create-wiki-page"
                                ProgramTest.Query.expectEmpty
                            )
                      , client.checkView 200
                            (ProgramTest.Query.withinId "host-admin-create-wiki-page"
                                ProgramTest.Query.expectHostAdminCreateWikiSlugInputUsesHtmlConstraints
                            )
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-slug") "notPascalCase"
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-name") "Story 29 Invalid Slug"
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-initial-admin-username") "story29badslug"
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-initial-admin-password") "password12"
                      , client.custom 100 (Effect.Browser.Dom.id "host-admin-create-wiki-form") "submit" (Json.Encode.object [])
                      , client.checkView 400
                            (ProgramTest.Query.withinId "host-admin-create-wiki-error"
                                (ProgramTest.Query.expectHasText invalidWikiSlugUserMessage)
                            )
                      ]
                    ]
        }
    ]
