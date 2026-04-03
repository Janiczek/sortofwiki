module ProgramTest.Story32_DeleteHostedWiki exposing (endToEndTests)

import Effect.Browser.Dom
import Env
import Expect
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "32 — delete hosted wiki: wrong confirm fails; slug confirm removes wiki from list"
        , config = ProgramTest.Config.emptyConfig
        , sessionId = "session-story32-delete-wiki"
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
                , client.clickLink 100 Wiki.hostAdminNewWikiUrlPath
                , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-slug") "Story32Wiki"
                , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-name") "Story 32 Wiki"
                , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-initial-admin-username") "story32admin"
                , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-initial-admin-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "host-admin-create-wiki-submit")
                , client.checkView 400
                    (ProgramTest.Query.withinHostAdminWikiRow "Story32Wiki"
                        (ProgramTest.Query.expectHasText "Story 32 Wiki")
                    )
                , client.clickLink 100 (Wiki.hostAdminWikiDetailUrlPath "Story32Wiki")
                , client.checkView 400
                    (ProgramTest.Query.withinId "host-admin-wiki-detail-page"
                        (ProgramTest.Query.expectHasWikiSlug "Story32Wiki")
                    )
                , client.input 100 (Effect.Browser.Dom.id "host-admin-delete-wiki-confirm") "not-the-slug"
                , client.click 100 (Effect.Browser.Dom.id "host-admin-delete-wiki-submit")
                , client.checkView 400
                    (ProgramTest.Query.withinId "host-admin-delete-wiki-error"
                        (ProgramTest.Query.expectHasText "Type the wiki slug exactly to confirm deletion.")
                    )
                , client.input 100 (Effect.Browser.Dom.id "host-admin-delete-wiki-confirm") "Story32Wiki"
                , client.click 100 (Effect.Browser.Dom.id "host-admin-delete-wiki-submit")
                , client.checkView 400
                    (ProgramTest.Query.expectDataAttributeOccurrenceCount "data-wiki-slug" "Story32Wiki" (\c -> c |> Expect.equal 0))
                ]
        }
    ]
