module ProgramTest.Story31_DeactivateHostedWiki exposing (endToEndTests)

import Effect.Browser.Dom
import Env
import Expect
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


elmTipsWikiHomeUrl : Url
elmTipsWikiHomeUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/ElmTips"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "31 — deactivate elm-tips: hidden from public catalog; /w/ElmTips is 404; host list shows Deactivated"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story31-deactivate-wiki"
        , path = "/admin"
        , connectClientMs = Just 200
        , clientSteps =
            \client ->
                [ client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                , client.click 100 (Effect.Browser.Dom.id "host-admin-login-submit")
                , client.checkView 300
                    (ProgramTest.Query.withinId "host-admin-wikis-list"
                        ProgramTest.Query.expectEmpty
                    )
                , client.clickLink 100 (Wiki.hostAdminWikiDetailUrlPath "ElmTips")
                , client.checkView 400
                    (ProgramTest.Query.withinId "host-admin-wiki-detail-status"
                        (ProgramTest.Query.expectHasText "Active")
                    )
                , client.click 100 (Effect.Browser.Dom.id "host-admin-wiki-detail-deactivate")
                , client.checkView 400
                    (ProgramTest.Query.withinId "host-admin-wiki-detail-status"
                        (ProgramTest.Query.expectHasText "Deactivated")
                    )
                , client.clickLink 100 "/"
                , client.checkView 400
                    (ProgramTest.Query.expectDataAttributeOccurrenceCount "data-wiki-slug" "ElmTips" (\c -> c |> Expect.equal 0))
                , client.checkView 100
                    (ProgramTest.Query.withinWikiCatalogRow "Demo"
                        (ProgramTest.Query.expectHasText "Demo Wiki")
                    )
                , client.update 100 (UrlChanged elmTipsWikiHomeUrl)
                , client.checkView 400
                    (ProgramTest.Query.withinLayoutHeader (ProgramTest.Query.expectHasText "Wiki not found"))
                , client.checkView 100
                    (ProgramTest.Query.expectDoesNotHaveAriaLabel "Wiki")
                , client.clickLink 100 Wiki.hostAdminWikisUrlPath
                , client.checkView 400
                    (ProgramTest.Query.withinDataAttributes
                        [ ( "data-context", "host-admin-wiki-row" )
                        , ( "data-wiki-slug", "ElmTips" )
                        , ( "data-wiki-active", "false" )
                        ]
                        (ProgramTest.Query.expectHasText "Deactivated")
                    )
                ]
        }
    ]
