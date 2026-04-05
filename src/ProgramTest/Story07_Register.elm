module ProgramTest.Story07_Register exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Model
import ProgramTest.Query
import ProgramTest.Start
import Route


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "Register on a wiki"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story07-register"
        , path = "/w/Demo/register"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.checkView 100 (ProgramTest.Query.expectPageShowsWikiSlug "wiki-register-page" "Demo")
                      , client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story07alice"
                      , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                    , [ client.checkModel 400
                            (ProgramTest.Model.expectRoute (Route.WikiHome "Demo")
                                "expected URL /w/Demo after registration"
                            )
                      ]
                    ]
        }
    ]
