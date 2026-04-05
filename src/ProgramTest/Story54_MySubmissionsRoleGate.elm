module ProgramTest.Story54_MySubmissionsRoleGate exposing (endToEndTests)

import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Model
import ProgramTest.Query
import ProgramTest.Start
import Route
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "My submissions: TrustedContributor doesn't see link and can't access"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story54-trusted-my-submissions"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "demo_trusted_publisher"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.checkView 100
                            (ProgramTest.Query.expectNoLinkWithHref (Wiki.mySubmissionsUrlPath "Demo"))
                      ]
                    , ProgramTest.Actions.navigateToPath (Wiki.mySubmissionsUrlPath "Demo") client
                    , [ client.checkModel 500
                            (ProgramTest.Model.expectRoute (Route.WikiHome "Demo")
                                "expected gated /submissions to resolve to wiki home for trusted moderator"
                            )
                      , client.checkView 200
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "My submissions: Admin doesn't see link and can't access"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story54-admin-my-submissions"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "demo_wiki_admin"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.checkView 100
                            (ProgramTest.Query.expectNoLinkWithHref (Wiki.mySubmissionsUrlPath "Demo"))
                      ]
                    , ProgramTest.Actions.navigateToPath (Wiki.mySubmissionsUrlPath "Demo") client
                    , [ client.checkModel 500
                            (ProgramTest.Model.expectRoute (Route.WikiHome "Demo")
                                "expected gated /submissions to resolve to wiki home for wiki admin"
                            )
                      , client.checkView 200
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "My submissions: UntrustedContributor sees link and can access"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , sessionId = "session-story54-untrusted-my-submissions"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "demo_contributor"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.checkView 100
                            (ProgramTest.Query.withinLinkHref (Wiki.mySubmissionsUrlPath "Demo")
                                (ProgramTest.Query.expectHasText "My submissions")
                            )
                      , client.clickLink 100 (Wiki.mySubmissionsUrlPath "Demo")
                      , client.checkView 400
                            (ProgramTest.Query.expectPageShowsWikiSlug "wiki-my-submissions-page" "Demo")
                      ]
                    ]
        }
    ]
