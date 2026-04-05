module ProgramTest.Story24_RevokeWikiAdmin exposing (endToEndTests)

import Backend
import Dict
import Effect.Browser.Dom
import Effect.Test
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki
import WikiRole


expectGrantadminTrustedOnDemo : Backend.Model -> Result String ()
expectGrantadminTrustedOnDemo backendModel =
    case Dict.get "Demo" backendModel.contributors of
        Nothing ->
            Err "missing demo contributors"

        Just byWiki ->
            case Dict.get "grantadmin_trusted" byWiki of
                Nothing ->
                    Err "missing grantadmin_trusted user"

                Just stored ->
                    case stored.role of
                        WikiRole.TrustedContributor ->
                            Ok ()

                        WikiRole.UntrustedContributor ->
                            Err "grantadmin_trusted should be Trusted after revoke"

                        WikiRole.Admin ->
                            Err "grantadmin_trusted should be Trusted after revoke (still Admin)"


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.startWith
        { name = "24 — wiki admin grants then revokes another admin; target is trusted in registry"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story24-revoke-flow"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.Actions.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "wikidemo"
                                , password = "password12"
                                }
                                client
                            , [ client.checkView 300
                                    (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                              , client.clickLink 100 (Wiki.adminUsersUrlPath "Demo")
                              , client.checkView 400
                                    (ProgramTest.Query.withinDataAttribute "data-admin-user"
                                        "wikidemo"
                                        (ProgramTest.Query.expectDoesNotHaveDataContext "wiki-admin-revoke-admin")
                                    )
                              , client.click 100
                                    (Effect.Browser.Dom.id "wiki-admin-grant-admin-grantadmin_trusted")
                              , client.checkView 600
                                    (ProgramTest.Query.withinDataAttribute "data-admin-user"
                                        "grantadmin_trusted"
                                        (ProgramTest.Query.withinDataAttribute "data-user-role"
                                            "Admin"
                                            (ProgramTest.Query.expectHasText "Admin")
                                        )
                                    )
                              , client.click 100
                                    (Effect.Browser.Dom.id "wiki-admin-revoke-admin-grantadmin_trusted")
                              , client.checkView 600
                                    (ProgramTest.Query.withinDataAttribute "data-admin-user"
                                        "grantadmin_trusted"
                                        (ProgramTest.Query.withinDataAttribute "data-user-role"
                                            "Trusted"
                                            (ProgramTest.Query.expectHasText "Trusted")
                                        )
                                    )
                              ]
                            ]
                }
            , Effect.Test.checkBackend 0 expectGrantadminTrustedOnDemo
            ]
        }
    ]
