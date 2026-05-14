module WikiAuditLogTest exposing (suite)

import Dict
import Expect
import Fuzz
import Test exposing (Test)
import Time
import WikiAuditLog


suite : Test
suite =
    Test.describe "WikiAuditLog"
        [ Test.describe "eventKindUserText"
            [ Test.test "ApprovedSubmission" <|
                \() ->
                    WikiAuditLog.ApprovedSubmission { submissionId = "sub_1", pageSlug = "home" }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Approved submission sub_1 (page home)"
            , Test.test "RejectedSubmission" <|
                \() ->
                    WikiAuditLog.RejectedSubmission { submissionId = "sub_x", pageSlug = "guides" }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Rejected submission sub_x (page guides)"
            , Test.test "RequestedSubmissionChanges" <|
                \() ->
                    WikiAuditLog.RequestedSubmissionChanges { submissionId = "sub_y", pageSlug = "a" }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Requested changes on submission sub_y (page a)"
            , Test.test "PromotedContributorToTrusted" <|
                \() ->
                    WikiAuditLog.PromotedContributorToTrusted { targetUsername = "alice" }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Promoted contributor alice to trusted"
            , Test.test "DemotedTrustedToContributor" <|
                \() ->
                    WikiAuditLog.DemotedTrustedToContributor { targetUsername = "bob" }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Demoted trusted contributor bob to contributor"
            , Test.test "GrantedWikiAdmin" <|
                \() ->
                    WikiAuditLog.GrantedWikiAdmin { targetUsername = "carol" }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Granted wiki admin to carol"
            , Test.test "RevokedWikiAdmin" <|
                \() ->
                    WikiAuditLog.RevokedWikiAdmin { targetUsername = "dave" }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Revoked wiki admin from dave"
            , Test.test "TrustedPublishedNewPage" <|
                \() ->
                    WikiAuditLog.TrustedPublishedNewPage
                        { pageSlug = "new-page"
                        , markdown = "Hello"
                        }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Trusted publish: created page new-page (5 chars)"
            , Test.test "TrustedPublishedPageEdit" <|
                \() ->
                    WikiAuditLog.TrustedPublishedPageEdit
                        { pageSlug = "home"
                        , beforeMarkdown = "Before"
                        , afterMarkdown = "After"
                        }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Trusted publish: edited page home (before: 6 chars, after: 5 chars)"
            , Test.test "TrustedPublishedPageDelete without reason text (legacy)" <|
                \() ->
                    WikiAuditLog.TrustedPublishedPageDelete { pageSlug = "gone", reason = "" }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Trusted publish: deleted page gone"
            , Test.test "TrustedPublishedPageDelete includes trimmed reason" <|
                \() ->
                    WikiAuditLog.TrustedPublishedPageDelete { pageSlug = "gone", reason = "  obsolete  " }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Trusted publish: deleted page gone — obsolete"
            ]
        , Test.describe "eventKindSummaryUserText"
            [ Test.test "TrustedPublishedNewPageSummary matches char-count style of full kind" <|
                \() ->
                    WikiAuditLog.TrustedPublishedNewPageSummary { pageSlug = "n", markdownCharCount = 5 }
                        |> WikiAuditLog.eventKindSummaryUserText
                        |> Expect.equal "Trusted publish: created page n (5 chars)"
            , Test.test "TrustedPublishedPageEditSummary matches before/after length style" <|
                \() ->
                    WikiAuditLog.TrustedPublishedPageEditSummary
                        { pageSlug = "h", beforeCharCount = 6, afterCharCount = 5 }
                        |> WikiAuditLog.eventKindSummaryUserText
                        |> Expect.equal "Trusted publish: edited page h (before: 6 chars, after: 5 chars)"
            , Test.test "TrustedPublishedPageDeleteSummary includes trimmed reason" <|
                \() ->
                    WikiAuditLog.TrustedPublishedPageDeleteSummary { pageSlug = "gone", reason = "  x  " }
                        |> WikiAuditLog.eventKindSummaryUserText
                        |> Expect.equal "Trusted publish: deleted page gone — x"
            ]
        , Test.describe "eventSummaryFromEvent"
            [ Test.test "drops trusted new-page markdown from summary kind" <|
                \() ->
                    let
                        ev : WikiAuditLog.AuditEvent
                        ev =
                            { at = Time.millisToPosix 0
                            , actorUsername = "t"
                            , kind =
                                WikiAuditLog.TrustedPublishedNewPage
                                    { pageSlug = "p"
                                    , markdown = "SECRET BODY"
                                    }
                            }
                    in
                    (WikiAuditLog.eventSummaryFromEvent ev).kind
                        |> Expect.equal
                            (WikiAuditLog.TrustedPublishedNewPageSummary
                                { pageSlug = "p", markdownCharCount = 11 }
                            )
            , Test.test "drops trusted edit before/after markdown from summary kind" <|
                \() ->
                    let
                        ev : WikiAuditLog.AuditEvent
                        ev =
                            { at = Time.millisToPosix 0
                            , actorUsername = "t"
                            , kind =
                                WikiAuditLog.TrustedPublishedPageEdit
                                    { pageSlug = "p"
                                    , beforeMarkdown = "OLD"
                                    , afterMarkdown = "NEW"
                                    }
                            }
                    in
                    (WikiAuditLog.eventSummaryFromEvent ev).kind
                        |> Expect.equal
                            (WikiAuditLog.TrustedPublishedPageEditSummary
                                { pageSlug = "p", beforeCharCount = 3, afterCharCount = 3 }
                            )
            ]
        , Test.describe "formatEventRowText"
            [ Test.test "includes UTC YYYY-MM-DD HH:mm:ss, actor, and kind text" <|
                \() ->
                    { at = Time.millisToPosix 1704067200000
                    , actorUsername = "mod"
                    , kind =
                        WikiAuditLog.ApprovedSubmission { submissionId = "s1", pageSlug = "p" }
                    }
                        |> WikiAuditLog.formatEventRowText
                        |> Expect.equal "2024-01-01 00:00:00 · mod — Approved submission s1 (page p)"
            , Test.test "drops milliseconds from UTC timestamp display" <|
                \() ->
                    { at = Time.millisToPosix 1
                    , actorUsername = "a"
                    , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                    }
                        |> WikiAuditLog.formatEventRowText
                        |> Expect.equal "1970-01-01 00:00:00 · a — Granted wiki admin to x"
            ]
        , Test.describe "append"
            [ Test.test "appends in chronological order for one wiki" <|
                \() ->
                    Dict.empty
                        |> WikiAuditLog.append "w" (Time.millisToPosix 1) "a" (WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" })
                        |> WikiAuditLog.append "w" (Time.millisToPosix 2) "b" (WikiAuditLog.RevokedWikiAdmin { targetUsername = "x" })
                        |> Dict.get "w"
                        |> Maybe.map (List.map .actorUsername)
                        |> Expect.equal (Just [ "a", "b" ])
            , Test.test "bumps millis when two appends share same wall clock on one wiki" <|
                \() ->
                    let
                        t : Time.Posix
                        t =
                            Time.millisToPosix 100
                    in
                    Dict.empty
                        |> WikiAuditLog.append "w" t "a" (WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" })
                        |> WikiAuditLog.append "w" t "b" (WikiAuditLog.RevokedWikiAdmin { targetUsername = "x" })
                        |> Dict.get "w"
                        |> Maybe.map (List.map (.at >> Time.posixToMillis))
                        |> Expect.equal (Just [ 100, 101 ])
            , Test.fuzz (Fuzz.intRange 0 500000) "three appends at identical requested time get sequential millis" <|
                \baseMillis ->
                    let
                        t : Time.Posix
                        t =
                            Time.millisToPosix baseMillis

                        kind1 : WikiAuditLog.AuditEventKind
                        kind1 =
                            WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }

                        kind2 : WikiAuditLog.AuditEventKind
                        kind2 =
                            WikiAuditLog.RevokedWikiAdmin { targetUsername = "x" }

                        kind3 : WikiAuditLog.AuditEventKind
                        kind3 =
                            WikiAuditLog.PromotedContributorToTrusted { targetUsername = "y" }
                    in
                    Dict.empty
                        |> WikiAuditLog.append "w" t "a" kind1
                        |> WikiAuditLog.append "w" t "b" kind2
                        |> WikiAuditLog.append "w" t "c" kind3
                        |> Dict.get "w"
                        |> Maybe.map (List.map (.at >> Time.posixToMillis))
                        |> Expect.equal (Just [ baseMillis, baseMillis + 1, baseMillis + 2 ])
            ]
        , Test.describe "test_posixAtUniqueAmongWikiEvents"
            [ Test.test "returns requested time when millis unused" <|
                \() ->
                    WikiAuditLog.test_posixAtUniqueAmongWikiEvents [] (Time.millisToPosix 7)
                        |> Time.posixToMillis
                        |> Expect.equal 7
            , Test.test "uses next free millis when requested slot taken" <|
                \() ->
                    let
                        existing : List WikiAuditLog.AuditEvent
                        existing =
                            [ { at = Time.millisToPosix 10
                              , actorUsername = "a"
                              , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                              }
                            , { at = Time.millisToPosix 12
                              , actorUsername = "b"
                              , kind = WikiAuditLog.RevokedWikiAdmin { targetUsername = "x" }
                              }
                            ]
                    in
                    WikiAuditLog.test_posixAtUniqueAmongWikiEvents existing (Time.millisToPosix 10)
                        |> Time.posixToMillis
                        |> Expect.equal 11
            , Test.test "bumps past a contiguous block of taken millis" <|
                \() ->
                    let
                        existing : List WikiAuditLog.AuditEvent
                        existing =
                            [ { at = Time.millisToPosix 2
                              , actorUsername = "a"
                              , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                              }
                            , { at = Time.millisToPosix 3
                              , actorUsername = "b"
                              , kind = WikiAuditLog.RevokedWikiAdmin { targetUsername = "x" }
                              }
                            ]
                    in
                    WikiAuditLog.test_posixAtUniqueAmongWikiEvents existing (Time.millisToPosix 2)
                        |> Time.posixToMillis
                        |> Expect.equal 4
            ]
        , Test.describe "eventMatchesFilter"
            [ Test.test "empty filter matches any event" <|
                \() ->
                    let
                        ev : WikiAuditLog.AuditEvent
                        ev =
                            { at = Time.millisToPosix 1
                            , actorUsername = "alice"
                            , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "bob" }
                            }
                    in
                    WikiAuditLog.eventMatchesFilter WikiAuditLog.emptyAuditLogFilter ev
                        |> Expect.equal True
            , Test.test "actor substring matches case-insensitively" <|
                \() ->
                    let
                        ev : WikiAuditLog.AuditEvent
                        ev =
                            { at = Time.millisToPosix 1
                            , actorUsername = "WikiDemo"
                            , kind = WikiAuditLog.PromotedContributorToTrusted { targetUsername = "x" }
                            }

                        f : WikiAuditLog.AuditLogFilter
                        f =
                            { actorUsernameSubstring = "wiki"
                            , pageSlugSubstring = ""
                            , eventKindTags = []
                            }
                    in
                    WikiAuditLog.eventMatchesFilter f ev
                        |> Expect.equal True
            , Test.test "page substring does not match role-only events" <|
                \() ->
                    let
                        ev : WikiAuditLog.AuditEvent
                        ev =
                            { at = Time.millisToPosix 1
                            , actorUsername = "a"
                            , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                            }

                        f : WikiAuditLog.AuditLogFilter
                        f =
                            { actorUsernameSubstring = ""
                            , pageSlugSubstring = "home"
                            , eventKindTags = []
                            }
                    in
                    WikiAuditLog.eventMatchesFilter f ev
                        |> Expect.equal False
            , Test.test "page substring matches submission events with page slug" <|
                \() ->
                    let
                        ev : WikiAuditLog.AuditEvent
                        ev =
                            { at = Time.millisToPosix 1
                            , actorUsername = "r"
                            , kind = WikiAuditLog.ApprovedSubmission { submissionId = "s1", pageSlug = "guides-home" }
                            }

                        f : WikiAuditLog.AuditLogFilter
                        f =
                            { actorUsernameSubstring = ""
                            , pageSlugSubstring = "home"
                            , eventKindTags = []
                            }
                    in
                    WikiAuditLog.eventMatchesFilter f ev
                        |> Expect.equal True
            , Test.test "selected kind tags OR-match" <|
                \() ->
                    let
                        evGrant : WikiAuditLog.AuditEvent
                        evGrant =
                            { at = Time.millisToPosix 1
                            , actorUsername = "a"
                            , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                            }

                        f : WikiAuditLog.AuditLogFilter
                        f =
                            { actorUsernameSubstring = ""
                            , pageSlugSubstring = ""
                            , eventKindTags =
                                [ WikiAuditLog.RejectedSubmissionKind
                                , WikiAuditLog.GrantedWikiAdminKind
                                ]
                            }
                    in
                    WikiAuditLog.eventMatchesFilter f evGrant
                        |> Expect.equal True
            , Test.test "selected kind tags exclude non-matching kinds" <|
                \() ->
                    let
                        ev : WikiAuditLog.AuditEvent
                        ev =
                            { at = Time.millisToPosix 1
                            , actorUsername = "a"
                            , kind = WikiAuditLog.PromotedContributorToTrusted { targetUsername = "x" }
                            }

                        f : WikiAuditLog.AuditLogFilter
                        f =
                            { actorUsernameSubstring = ""
                            , pageSlugSubstring = ""
                            , eventKindTags = [ WikiAuditLog.GrantedWikiAdminKind ]
                            }
                    in
                    WikiAuditLog.eventMatchesFilter f ev
                        |> Expect.equal False
            ]
        , Test.describe "auditEventByAtMillisInList"
            [ Test.test "finds single row" <|
                \() ->
                    let
                        ev : WikiAuditLog.AuditEvent
                        ev =
                            { at = Time.millisToPosix 4242
                            , actorUsername = "u"
                            , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                            }
                    in
                    WikiAuditLog.auditEventByAtMillisInList 4242 [ ev ]
                        |> Expect.equal (Just ev)
            , Test.test "when several rows share millis, returns last in list" <|
                \() ->
                    let
                        first : WikiAuditLog.AuditEvent
                        first =
                            { at = Time.millisToPosix 1
                            , actorUsername = "a"
                            , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                            }

                        second : WikiAuditLog.AuditEvent
                        second =
                            { at = Time.millisToPosix 1
                            , actorUsername = "b"
                            , kind = WikiAuditLog.RevokedWikiAdmin { targetUsername = "x" }
                            }
                    in
                    WikiAuditLog.auditEventByAtMillisInList 1 [ first, second ]
                        |> Expect.equal (Just second)
            , Test.fuzz (Fuzz.intRange 1 500000) "recovers row when millis are unique in list" <|
                \m ->
                    let
                        ev : WikiAuditLog.AuditEvent
                        ev =
                            { at = Time.millisToPosix m
                            , actorUsername = "f"
                            , kind = WikiAuditLog.PromotedContributorToTrusted { targetUsername = "u" }
                            }
                    in
                    WikiAuditLog.auditEventByAtMillisInList m [ ev ]
                        |> Expect.equal (Just ev)
            ]
        , Test.describe "auditDiffCacheKey"
            [ Test.test "uses wiki slug and millis only" <|
                \() ->
                    WikiAuditLog.auditDiffCacheKey "Demo" 1704067200000
                        |> Expect.equal "Demo\u{001E}1704067200000"
            ]
        , Test.describe "hostAuditDiffCacheKey"
            [ Test.test "uses host prefix, wiki slug, and millis" <|
                \() ->
                    WikiAuditLog.hostAuditDiffCacheKey "ElmTips" 42
                        |> Expect.equal "host\u{001E}ElmTips\u{001E}42"
            ]
        , Test.describe "scopedAuditEventByWikiAndAtMillis"
            [ Test.test "matches wiki and millis" <|
                \() ->
                    let
                        ev : WikiAuditLog.ScopedAuditEvent
                        ev =
                            { wikiSlug = "Demo"
                            , at = Time.millisToPosix 7
                            , actorUsername = "a"
                            , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                            }
                    in
                    WikiAuditLog.scopedAuditEventByWikiAndAtMillis "Demo" 7 [ ev ]
                        |> Expect.equal (Just ev)
            , Test.test "wrong wiki slug yields Nothing" <|
                \() ->
                    let
                        ev : WikiAuditLog.ScopedAuditEvent
                        ev =
                            { wikiSlug = "Demo"
                            , at = Time.millisToPosix 7
                            , actorUsername = "a"
                            , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                            }
                    in
                    WikiAuditLog.scopedAuditEventByWikiAndAtMillis "ElmTips" 7 [ ev ]
                        |> Expect.equal Nothing
            ]
        , Test.describe "scopedAuditEventByAtMillisWhenWikiUnambiguous"
            [ Test.test "returns Just when exactly one wiki matches millis" <|
                \() ->
                    let
                        ev : WikiAuditLog.ScopedAuditEvent
                        ev =
                            { wikiSlug = "Demo"
                            , at = Time.millisToPosix 9
                            , actorUsername = "a"
                            , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                            }
                    in
                    WikiAuditLog.scopedAuditEventByAtMillisWhenWikiUnambiguous 9 [ ev ]
                        |> Expect.equal (Just ev)
            , Test.test "returns Nothing when two wikis share millis" <|
                \() ->
                    let
                        a : WikiAuditLog.ScopedAuditEvent
                        a =
                            { wikiSlug = "Demo"
                            , at = Time.millisToPosix 3
                            , actorUsername = "a"
                            , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                            }

                        b : WikiAuditLog.ScopedAuditEvent
                        b =
                            { wikiSlug = "ElmTips"
                            , at = Time.millisToPosix 3
                            , actorUsername = "b"
                            , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "y" }
                            }
                    in
                    WikiAuditLog.scopedAuditEventByAtMillisWhenWikiUnambiguous 3 [ a, b ]
                        |> Expect.equal Nothing
            ]
        , Test.describe "allScopedEventsFromDict"
            [ Test.test "merges wikis and sorts by time" <|
                \() ->
                    Dict.empty
                        |> WikiAuditLog.append "B" (Time.millisToPosix 200) "a" (WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" })
                        |> WikiAuditLog.append "A" (Time.millisToPosix 100) "b" (WikiAuditLog.GrantedWikiAdmin { targetUsername = "y" })
                        |> WikiAuditLog.allScopedEventsFromDict
                        |> List.map (\e -> ( e.wikiSlug, Time.posixToMillis e.at ))
                        |> Expect.equal [ ( "A", 100 ), ( "B", 200 ) ]
            ]
        , Test.describe "scopedEventMatchesFilter"
            [ Test.test "wiki slug substring is case-insensitive" <|
                \() ->
                    let
                        ev : WikiAuditLog.ScopedAuditEvent
                        ev =
                            { wikiSlug = "Demo"
                            , at = Time.millisToPosix 1
                            , actorUsername = "a"
                            , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                            }

                        f : WikiAuditLog.HostAuditLogFilter
                        f =
                            { wikiSlugSubstring = "emo"
                            , actorUsernameSubstring = ""
                            , pageSlugSubstring = ""
                            , eventKindTags = []
                            }
                    in
                    WikiAuditLog.scopedEventMatchesFilter f ev
                        |> Expect.equal True
            ]
        ]
