module ProgramTest.Story50_MySubmissionsList exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Config
import ProgramTest.LoginSteps
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "50 — contributor sees My submissions link and pending rows (statusdemo)"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , sessionId = "session-story50-my-submissions"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.LoginSteps.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "statusdemo"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.checkView 100
                            (ProgramTest.Query.withinLinkHref (Wiki.mySubmissionsUrlPath "Demo")
                                (ProgramTest.Query.expectHasText "My submissions")
                            )
                      , client.clickLink 100 (Wiki.mySubmissionsUrlPath "Demo")
                      , client.checkView 400
                            (ProgramTest.Query.expectPageShowsWikiSlug "wiki-my-submissions-page" "Demo")
                      , client.checkView 100
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.withinId "wiki-my-submissions-page"
                                    (ProgramTest.Query.withinDataAttribute "data-my-submissions-item" "sub_2"
                                        (ProgramTest.Query.expectHasText "sub_2")
                                    )
                                , ProgramTest.Query.withinId "wiki-my-submissions-page"
                                    (ProgramTest.Query.withinDataAttribute "data-my-submissions-item" "sub_1"
                                        (ProgramTest.Query.expectHasText "sub_1")
                                    )
                                ]
                            )
                      ]
                ]
        }
    , ProgramTest.Start.start
        { name = "50 — new contributor sees empty my submissions list"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story50-empty"
        , path = "/w/Demo/register"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story50emptyuser"
                , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                , client.checkView 300
                    (ProgramTest.Query.withinId "wiki-register-success"
                        (ProgramTest.Query.expectHasText "Registration complete")
                    )
                , client.clickLink 100 (Wiki.mySubmissionsUrlPath "Demo")
                , client.checkView 400
                    (ProgramTest.Query.withinId "wiki-my-submissions-empty"
                        (ProgramTest.Query.expectHasText "No submissions to show here yet.")
                    )
                ]
        }
    ]
