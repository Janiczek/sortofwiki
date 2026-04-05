module ProgramTest.Story13_ReviewerNotes exposing (endToEndTests)

import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "13 — contributor sees seeded reviewer note on sub_3 (statusdemo / password12)"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , sessionId = "session-story13-reviewer-note"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "statusdemo"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.clickLink 100 (Wiki.mySubmissionsUrlPath "Demo")
                      , client.clickLink 100 (Wiki.submissionDetailUrlPath "Demo" "sub_3")
                      , client.checkView 400
                            (ProgramTest.Query.withinId "wiki-submission-detail-reviewer-note"
                                (ProgramTest.Query.expectHasText "Seeded reviewer note (story 13)")
                            )
                      ]
                    ]
        }
    ]
