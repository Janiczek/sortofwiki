module ProgramTest.Story55_MarkdownKitchenSink exposing (endToEndTests)

import Expect
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Test.Html.Query
import Test.Html.Selector


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "55 — KitchenSink: $$ → inline-equation, $$$ → block-equation; Markdown features render"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story55-kitchen-sink"
        , path = "/w/Demo/p/KitchenSink"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.withinId "page-markdown"
                        (ProgramTest.Query.expectAll
                            [ \md ->
                                ProgramTest.Query.withinDataAttribute "data-equation"
                                    "progtestStory55Inline"
                                    (\eq ->
                                        Test.Html.Query.has [ Test.Html.Selector.tag "inline-equation" ] eq
                                    )
                                    md
                            , \md ->
                                ProgramTest.Query.withinDataAttribute "data-equation"
                                    "progtestStory55Block"
                                    (\eq ->
                                        Test.Html.Query.has [ Test.Html.Selector.tag "block-equation" ] eq
                                    )
                                    md
                            , \md -> ProgramTest.Query.expectTagOccurrenceCount "inline-equation" (Expect.equal 1) md
                            , \md -> ProgramTest.Query.expectTagOccurrenceCount "block-equation" (Expect.equal 1) md
                            , \md -> ProgramTest.Query.expectHasText "Kitchen sink" md
                            , \md -> ProgramTest.Query.withinTag "h3" (ProgramTest.Query.expectHasText "Third level") md
                            , \md -> ProgramTest.Query.expectHasText "Bold" md
                            , \md -> ProgramTest.Query.expectHasText "italic" md
                            , \md -> ProgramTest.Query.expectHasText "inline code" md
                            , \md -> ProgramTest.Query.expectHasText "strikethrough" md
                            , \md -> ProgramTest.Query.expectLink { href = "https://example.com/kitchen-sink", label = "External link" } md
                            , \md -> ProgramTest.Query.expectLink { href = "/w/Demo/p/Guides", label = "Guides" } md
                            , \md -> ProgramTest.Query.expectLink { href = "/w/Demo/p/About", label = "About this wiki" } md
                            , \md -> ProgramTest.Query.expectLink { href = "https://example.net", label = "https://example.net" } md
                            , \md ->
                                ProgramTest.Query.withinTagAndHref "a"
                                    "/w/Demo/p/Story55MissingPage"
                                    (ProgramTest.Query.expectHasClass "!text-red-700")
                                    md
                            , \md -> ProgramTest.Query.expectHasText "Open task" md
                            , \md -> ProgramTest.Query.expectHasText "Done task" md
                            , \md -> ProgramTest.Query.expectHasText "Bullet one" md
                            , \md -> ProgramTest.Query.expectHasText "Nested bullet" md
                            , \md -> ProgramTest.Query.expectHasText "Ordered one" md
                            , \md -> ProgramTest.Query.expectHasText "Nested under ordered" md
                            , \md -> ProgramTest.Query.expectHasText "Header A" md
                            , \md -> ProgramTest.Query.expectHasTexts [ "Cell", "1" ] md
                            , \md -> ProgramTest.Query.expectHasText "Quoted line one." md
                            , \md -> ProgramTest.Query.expectHasText "Tick" md
                            , \md -> ProgramTest.Query.expectTagOccurrenceCount "table" (Expect.atLeast 1) md
                            , \md -> ProgramTest.Query.expectTagOccurrenceCount "hr" (Expect.atLeast 1) md
                            , \md -> ProgramTest.Query.expectHasText "Line one" md
                            , \md -> ProgramTest.Query.expectHasText "Line two" md
                            ]
                        )
                    )
                ]
        }
    ]
