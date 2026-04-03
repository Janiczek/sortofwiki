module ProgramTest.Story30_EditHostedWikiMetadata exposing (endToEndTests)

import Effect.Browser.Dom
import Env
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "30 — host admin edit demo wiki summary"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story30-host-wiki-metadata"
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
                , client.clickLink 100 (Wiki.hostAdminWikiDetailUrlPath "Demo")
                , client.checkView 400
                    (ProgramTest.Query.withinId "host-admin-wiki-detail-page"
                        ProgramTest.Query.expectEmpty
                    )
                , client.input 100 (Effect.Browser.Dom.id "host-admin-wiki-detail-summary") "STORY30_UPDATED_SUMMARY"
                , client.click 100 (Effect.Browser.Dom.id "host-admin-wiki-detail-save")
                , client.checkView 400
                    (ProgramTest.Query.withinId "host-admin-wiki-detail-summary"
                        (ProgramTest.Query.expectHasInputValue "STORY30_UPDATED_SUMMARY")
                    )
                ]
        }
    , ProgramTest.Start.start
        { name = "30 — host admin renames hosted wiki slug"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story30-host-wiki-slug-rename"
        , path = "/admin"
        , connectClientMs = Just 201
        , clientSteps =
            \client ->
                [ client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                , client.click 100 (Effect.Browser.Dom.id "host-admin-login-submit")
                , client.checkView 300
                    (ProgramTest.Query.withinId "host-admin-wikis-list"
                        ProgramTest.Query.expectEmpty
                    )
                , client.clickLink 100 (Wiki.hostAdminWikiDetailUrlPath "Demo")
                , client.checkView 400
                    (ProgramTest.Query.withinId "host-admin-wiki-detail-page"
                        ProgramTest.Query.expectEmpty
                    )
                , client.input 100 (Effect.Browser.Dom.id "host-admin-wiki-detail-slug") "Story30slugRenamed"
                , client.click 100 (Effect.Browser.Dom.id "host-admin-wiki-detail-save")
                , client.checkView 500
                    (ProgramTest.Query.withinIdAndDataAttributes "host-admin-wiki-detail-page"
                        [ ( "data-wiki-slug", "Story30slugRenamed" ) ]
                        ProgramTest.Query.expectEmpty
                    )
                , client.checkView 100
                    (ProgramTest.Query.withinId "host-admin-wiki-detail-slug"
                        (ProgramTest.Query.expectHasInputValue "Story30slugRenamed")
                    )
                ]
        }
    ]
