module ProgramTest.Story04_PublishedPage exposing (endToEndTests)

import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Test.Html.Selector
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "See wiki page content on /w/Demo/p/Guides"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-published-page-guides"
        , path = "/w/Demo/p/Guides"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinId "page-published-page"
                            (ProgramTest.Query.expectHasDataAttributes
                                [ ( "data-wiki-slug", "Demo" )
                                , ( "data-page-slug", "Guides" )
                                ]
                            )
                        , ProgramTest.Query.withinPageMarkdownHeading "h2"
                            (ProgramTest.Query.expectHasText "How to use this wiki")
                        , ProgramTest.Query.withinId "page-article-toc"
                            (ProgramTest.Query.withinTag "a"
                                (ProgramTest.Query.expectAll
                                    [ ProgramTest.Query.expectHasText "How to use this wiki"
                                    , ProgramTest.Query.expectHasHref "#how-to-use-this-wiki"
                                    ]
                                )
                            )
                        , ProgramTest.Query.withinId "page-edit-link"
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.expectHasText "Edit page"
                                , ProgramTest.Query.expectHasHref "/w/Demo/edit/Guides"
                                ]
                            )
                        , ProgramTest.Query.withinId "page-markdown"
                            (ProgramTest.Query.withinTag "strong"
                                (ProgramTest.Query.expectHasText "manual")
                            )
                        ]
                    )
                ]
        }
    , ProgramTest.Start.start
        { name = "See '[[Unknown]]: Create?' on /w/Demo/p/Unknown"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-published-page-missing"
        , path = "/w/Demo/p/Unknown"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinLayoutHeader
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.expectHasText ": Create?"
                                , ProgramTest.Query.expectHasText "Unknown"
                                ]
                            )
                        , ProgramTest.Query.withinId "wiki-missing-published-page"
                            (ProgramTest.Query.expectDescendantMatchesEvery
                                [ Test.Html.Selector.text "The page \"Unknown\" does not exist yet."
                                , Test.Html.Selector.id "wiki-missing-published-login-link"
                                ]
                            )
                        , ProgramTest.Query.withinId "page-create-link"
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.expectHasText "Create page"
                                , ProgramTest.Query.expectHasHref
                                    (Wiki.submitNewPageUrlPathWithSuggestedSlug "Demo" "Unknown")
                                ]
                            )
                        ]
                    )
                ]
        }
    ]
