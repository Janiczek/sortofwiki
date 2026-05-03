module WikiStatsTest exposing (suite)

import Dict
import Expect
import Fuzz
import Fuzzers
import Page
import Test exposing (Test)
import Time
import Wiki
import WikiAuditLog
import WikiStats


auditEvent : WikiAuditLog.AuditEventKind -> WikiAuditLog.AuditEvent
auditEvent kind =
    { kind = kind
    , at = Time.millisToPosix 0
    , actorUsername = "alice"
    }


suite : Test
suite =
    Test.describe "WikiStats"
        [ Test.describe "buildFromViews"
            [ Test.test "empty view counts yields empty tops" <|
                \() ->
                    WikiStats.buildFromViews Dict.empty
                        |> .topPagesByViews
                        |> Expect.equal []
            , Test.test "single page view" <|
                \() ->
                    WikiStats.buildFromViews (Dict.singleton "Guide" 5)
                        |> .topPagesByViews
                        |> Expect.equal [ { pageSlug = "Guide", viewCount = 5 } ]
            , Test.test "top pages sorted descending" <|
                \() ->
                    Dict.fromList [ ( "A", 3 ), ( "B", 10 ), ( "C", 1 ) ]
                        |> WikiStats.buildFromViews
                        |> .topPagesByViews
                        |> List.map .viewCount
                        |> Expect.equal [ 10, 3, 1 ]
            , Test.fuzz
                (Fuzz.list (Fuzz.pair Fuzzers.pageSlug (Fuzz.intRange 0 1000)))
                "top pages sorted descending (PBT)"
              <|
                \pairs ->
                    let
                        tops : List { pageSlug : String, viewCount : Int }
                        tops =
                            pairs
                                |> Dict.fromList
                                |> WikiStats.buildFromViews
                                |> .topPagesByViews
                    in
                    tops
                        |> List.map .viewCount
                        |> (\vs -> vs == List.sortBy negate vs)
                        |> Expect.equal True
            ]
        , Test.describe "buildFromAudit"
            [ Test.test "empty events yields empty results" <|
                \() ->
                    WikiStats.buildFromAudit (Time.millisToPosix 0) []
                        |> (\r -> ( r.dailyActivityCounts, r.topPagesByEditEvents ))
                        |> Expect.equal ( [], [] )
            , Test.test "TrustedPublishedPageEdit increments daily edits" <|
                \() ->
                    WikiStats.buildFromAudit (Time.millisToPosix 0)
                        [ auditEvent (WikiAuditLog.TrustedPublishedPageEdit { pageSlug = "Guide", beforeMarkdown = "old", afterMarkdown = "new" }) ]
                        |> .dailyActivityCounts
                        |> List.map .edits
                        |> Expect.equal [ 1 ]
            , Test.test "TrustedPublishedNewPage increments daily creates" <|
                \() ->
                    WikiStats.buildFromAudit (Time.millisToPosix 0)
                        [ auditEvent (WikiAuditLog.TrustedPublishedNewPage { pageSlug = "NewPage", markdown = "# NewPage" }) ]
                        |> .dailyActivityCounts
                        |> List.map .creates
                        |> Expect.equal [ 1 ]
            , Test.test "TrustedPublishedPageDelete increments daily deletes" <|
                \() ->
                    WikiStats.buildFromAudit (Time.millisToPosix 0)
                        [ auditEvent (WikiAuditLog.TrustedPublishedPageDelete { pageSlug = "OldPage", reason = "outdated" }) ]
                        |> .dailyActivityCounts
                        |> List.map .deletes
                        |> Expect.equal [ 1 ]
            , Test.test "fills zero creates on UTC days between last activity and asOf" <|
                \() ->
                    WikiStats.buildFromAudit (Time.millisToPosix (2 * 86400000))
                        [ auditEvent (WikiAuditLog.TrustedPublishedNewPage { pageSlug = "A", markdown = "# A" }) ]
                        |> .dailyActivityCounts
                        |> List.map .creates
                        |> Expect.equal [ 1, 0, 0 ]
            , Test.test "ApprovedPublishedPageEdit counted as edit in top pages" <|
                \() ->
                    WikiStats.buildFromAudit (Time.millisToPosix 0)
                        [ auditEvent (WikiAuditLog.ApprovedPublishedPageEdit { submissionId = "s1", pageSlug = "Guide" }) ]
                        |> .topPagesByEditEvents
                        |> Expect.equal [ { pageSlug = "Guide", editCount = 1 } ]
            , Test.fuzz
                (Fuzz.list Fuzzers.pageSlug)
                "all daily counts are non-negative (PBT)"
              <|
                \slugs ->
                    let
                        events : List WikiAuditLog.AuditEvent
                        events =
                            slugs
                                |> List.map
                                    (\s -> auditEvent (WikiAuditLog.TrustedPublishedPageEdit { pageSlug = s, beforeMarkdown = "", afterMarkdown = "" }))
                    in
                    WikiStats.buildFromAudit (Time.millisToPosix 0) events
                        |> .dailyActivityCounts
                        |> List.all (\r -> r.creates >= 0 && r.edits >= 0 && r.deletes >= 0)
                        |> Expect.equal True
            ]
        , Test.describe "merge"
            [ Test.test "changing fromViews does not affect wiki/audit fields" <|
                \() ->
                    let
                        fromWiki : WikiStats.FromWiki
                        fromWiki =
                            { publishedPageCount = 10
                            , missingPageCount = 2
                            , totalPublishedLinks = 30
                            , totalTags = 5
                            , topPagesByRevision = [ { pageSlug = "A", revision = 3 } ]
                            , topPagesByInLinks = []
                            , topPagesByOutLinks = []
                            , avgRevisionPerPage = 1.5
                            , dailyAccumulatedSnapshots = []
                            }

                        fromAudit : WikiStats.FromAudit
                        fromAudit =
                            { dailyActivityCounts = [ { day = "2026-01-01", creates = 1, edits = 2, deletes = 0 } ]
                            , topPagesByEditEvents = [ { pageSlug = "A", editCount = 5 } ]
                            }

                        s1 : WikiStats.Summary
                        s1 =
                            WikiStats.merge fromWiki fromAudit { topPagesByViews = [ { pageSlug = "A", viewCount = 100 } ] }

                        s2 : WikiStats.Summary
                        s2 =
                            WikiStats.merge fromWiki fromAudit { topPagesByViews = [ { pageSlug = "B", viewCount = 9999 } ] }
                    in
                    Expect.all
                        [ \_ -> s1.publishedPageCount |> Expect.equal s2.publishedPageCount
                        , \_ -> s1.topPagesByRevision |> Expect.equal s2.topPagesByRevision
                        , \_ -> s1.dailyActivityCounts |> Expect.equal s2.dailyActivityCounts
                        , \_ -> s1.topPagesByEditEvents |> Expect.equal s2.topPagesByEditEvents
                        , \_ -> s1.topPagesByInLinks |> Expect.equal s2.topPagesByInLinks
                        , \_ -> s1.topPagesByOutLinks |> Expect.equal s2.topPagesByOutLinks
                        , \_ -> s1.dailyAccumulatedSnapshots |> Expect.equal s2.dailyAccumulatedSnapshots
                        ]
                        ()
            , Test.test "changing fromWiki does not affect audit/views fields" <|
                \() ->
                    let
                        fromAudit : WikiStats.FromAudit
                        fromAudit =
                            { dailyActivityCounts = [ { day = "2026-02-01", creates = 2, edits = 5, deletes = 1 } ]
                            , topPagesByEditEvents = [ { pageSlug = "X", editCount = 10 } ]
                            }

                        fromViews : WikiStats.FromViews
                        fromViews =
                            { topPagesByViews = [ { pageSlug = "X", viewCount = 42 } ] }

                        makeWiki : Int -> WikiStats.FromWiki
                        makeWiki n =
                            { publishedPageCount = n
                            , missingPageCount = 0
                            , totalPublishedLinks = 0
                            , totalTags = 0
                            , topPagesByRevision = []
                            , topPagesByInLinks = []
                            , topPagesByOutLinks = []
                            , avgRevisionPerPage = 0.0
                            , dailyAccumulatedSnapshots = []
                            }

                        s1 : WikiStats.Summary
                        s1 =
                            WikiStats.merge (makeWiki 1) fromAudit fromViews

                        s2 : WikiStats.Summary
                        s2 =
                            WikiStats.merge (makeWiki 999) fromAudit fromViews
                    in
                    Expect.all
                        [ \_ -> s1.dailyActivityCounts |> Expect.equal s2.dailyActivityCounts
                        , \_ -> s1.topPagesByEditEvents |> Expect.equal s2.topPagesByEditEvents
                        , \_ -> s1.topPagesByViews |> Expect.equal s2.topPagesByViews
                        , \_ -> s1.topPagesByInLinks |> Expect.equal s2.topPagesByInLinks
                        , \_ -> s1.topPagesByOutLinks |> Expect.equal s2.topPagesByOutLinks
                        , \_ -> s1.dailyAccumulatedSnapshots |> Expect.equal s2.dailyAccumulatedSnapshots
                        ]
                        ()
            ]
        , Test.describe "buildFromWiki"
            [ Test.test "daily accumulated snapshots grow with trusted new pages on distinct UTC days" <|
                \() ->
                    let
                        wikiSlug : String
                        wikiSlug =
                            "Demo"

                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages wikiSlug "" Dict.empty

                        day0 : Time.Posix
                        day0 =
                            Time.millisToPosix 0

                        day1 : Time.Posix
                        day1 =
                            Time.millisToPosix 86400000

                        events : List WikiAuditLog.AuditEvent
                        events =
                            [ { kind = WikiAuditLog.TrustedPublishedNewPage { pageSlug = "A", markdown = "# A" }
                              , at = day0
                              , actorUsername = "alice"
                              }
                            , { kind = WikiAuditLog.TrustedPublishedNewPage { pageSlug = "B", markdown = "# B" }
                              , at = day1
                              , actorUsername = "alice"
                              }
                            ]

                        asOf : Time.Posix
                        asOf =
                            Time.millisToPosix 86400000

                        fromWiki : WikiStats.FromWiki
                        fromWiki =
                            WikiStats.buildFromWiki wikiSlug wiki Dict.empty events asOf
                    in
                    Expect.all
                        [ \_ ->
                            fromWiki.dailyAccumulatedSnapshots
                                |> List.map .publishedPages
                                |> Expect.equal [ 1, 2 ]
                        , \_ ->
                            fromWiki.publishedPageCount
                                |> Expect.equal 0
                        ]
                        ()
            , Test.test "trusted edit changes missing and todo counts in snapshot replay" <|
                \() ->
                    let
                        wikiSlug : String
                        wikiSlug =
                            "Demo"

                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages wikiSlug "" Dict.empty

                        day0 : Time.Posix
                        day0 =
                            Time.millisToPosix 0

                        events : List WikiAuditLog.AuditEvent
                        events =
                            [ { kind = WikiAuditLog.TrustedPublishedNewPage { pageSlug = "A", markdown = "[[Missing]]" }
                              , at = day0
                              , actorUsername = "alice"
                              }
                            , { kind =
                                    WikiAuditLog.TrustedPublishedPageEdit
                                        { pageSlug = "A"
                                        , beforeMarkdown = "[[Missing]]"
                                        , afterMarkdown = "{TODO: fix}"
                                        }
                              , at = Time.millisToPosix 1000
                              , actorUsername = "alice"
                              }
                            ]

                        fromWiki : WikiStats.FromWiki
                        fromWiki =
                            WikiStats.buildFromWiki wikiSlug wiki Dict.empty events day0

                        snap : WikiStats.DailyAccumulatedSnapshot
                        snap =
                            fromWiki.dailyAccumulatedSnapshots
                                |> List.reverse
                                |> List.head
                                |> Maybe.withDefault { day = "", publishedPages = 0, missingPages = 0, todos = 0 }
                    in
                    Expect.all
                        [ \_ -> snap.publishedPages |> Expect.equal 1
                        , \_ -> snap.missingPages |> Expect.equal 0
                        , \_ -> snap.todos |> Expect.equal 1
                        ]
                        ()
            , Test.test "top in-links and out-links include markdown links and tags" <|
                \() ->
                    let
                        wikiSlug : String
                        wikiSlug =
                            "Demo"

                        pageA : Page.Page
                        pageA =
                            Page.withPublished "A" "[[B]]"
                                |> (\p -> { p | tags = [ "B" ] })

                        pageB : Page.Page
                        pageB =
                            Page.withPublished "B" ""

                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages wikiSlug
                                ""
                                (Dict.fromList [ ( "A", pageA ), ( "B", pageB ) ])

                        fromWiki : WikiStats.FromWiki
                        fromWiki =
                            WikiStats.buildFromWiki wikiSlug wiki Dict.empty [] (Time.millisToPosix 0)
                    in
                    Expect.all
                        [ \_ ->
                            fromWiki.topPagesByInLinks
                                |> List.filter (\r -> r.pageSlug == "B")
                                |> List.head
                                |> Maybe.map .inLinkCount
                                |> Expect.equal (Just 2)
                        , \_ ->
                            fromWiki.topPagesByOutLinks
                                |> List.filter (\r -> r.pageSlug == "A")
                                |> List.head
                                |> Maybe.map .outLinkCount
                                |> Expect.equal (Just 2)
                        ]
                        ()
            ]
        ]
