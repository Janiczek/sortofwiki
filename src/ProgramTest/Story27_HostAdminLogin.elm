module ProgramTest.Story27_HostAdminLogin exposing (endToEndTests)

import Effect.Browser.Dom
import Env
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "27 — host admin login /admin"
        , config = ProgramTest.Config.emptyConfig
        , sessionId = "session-story27-host-admin"
        , path = "/admin"
        , connectClientMs = Just 200
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.checkView 100
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.headingIs "SortOfWiki"
                                , ProgramTest.Query.subheadingIs "Admin: Login"
                                ]
                            )
                      ]
                    , ProgramTest.Actions.navigateToPath Wiki.hostAdminWikisUrlPath client
                    , [ client.checkView 200
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.headingIs "SortOfWiki"
                                , ProgramTest.Query.subheadingIs "Admin: Login"
                                ]
                            )
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") "wrong-password"
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "host-admin-login-form" client
                    , [ client.checkView 200
                            (ProgramTest.Query.withinId "host-admin-login-error"
                                (ProgramTest.Query.expectHasText "Invalid password.")
                            )
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "host-admin-login-form" client
                    , [ client.checkView 300
                            (ProgramTest.Query.withinId "host-admin-wikis-list"
                                (ProgramTest.Query.expectHasText "No wikis present")
                            )
                      , client.checkView 400
                            (ProgramTest.Query.expectHasNotId "host-admin-login-form")
                      , client.checkView 100
                            (ProgramTest.Query.withinAriaLabel "Site"
                                (ProgramTest.Query.expectHasTexts
                                    [ "Host admin"
                                    , "Hosted wikis"
                                    , "Add wiki"
                                    ]
                                )
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "27 — host admin login via form submit (Enter path)"
        , config = ProgramTest.Config.emptyConfig
        , sessionId = "session-story27-host-admin-form-submit"
        , path = "/admin"
        , connectClientMs = Just 200
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.checkView 100
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.headingIs "SortOfWiki"
                                , ProgramTest.Query.subheadingIs "Admin: Login"
                                ]
                            )
                      ]
                    , ProgramTest.Actions.navigateToPath Wiki.hostAdminWikisUrlPath client
                    , [ client.checkView 200
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.headingIs "SortOfWiki"
                                , ProgramTest.Query.subheadingIs "Admin: Login"
                                ]
                            )
                      ]
                    , ProgramTest.Actions.submitHostAdminLoginFormViaFormSubmit Env.hostAdminPassword client
                    , [ client.checkView 300
                            (ProgramTest.Query.withinId "host-admin-wikis-list"
                                (ProgramTest.Query.expectHasText "No wikis present")
                            )
                      , client.checkView 400
                            (ProgramTest.Query.expectHasNotId "host-admin-login-form")
                      ]
                    ]
        }
    ]
