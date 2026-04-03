module WikiAuditLogTest exposing (suite)

import Dict
import Expect
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
                    WikiAuditLog.TrustedPublishedNewPage { pageSlug = "new-page" }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Trusted publish: created page new-page"
            , Test.test "TrustedPublishedPageEdit" <|
                \() ->
                    WikiAuditLog.TrustedPublishedPageEdit { pageSlug = "home" }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Trusted publish: edited page home"
            , Test.test "TrustedPublishedPageDelete" <|
                \() ->
                    WikiAuditLog.TrustedPublishedPageDelete { pageSlug = "gone" }
                        |> WikiAuditLog.eventKindUserText
                        |> Expect.equal "Trusted publish: deleted page gone"
            ]
        , Test.describe "formatEventRowText"
            [ Test.test "includes UTC YYYY-MM-DD HH:mm:ss.sss, actor, and kind text" <|
                \() ->
                    { at = Time.millisToPosix 1704067200000
                    , actorUsername = "mod"
                    , kind =
                        WikiAuditLog.ApprovedSubmission { submissionId = "s1", pageSlug = "p" }
                    }
                        |> WikiAuditLog.formatEventRowText
                        |> Expect.equal "2024-01-01 00:00:00.000 · mod — Approved submission s1 (page p)"
            , Test.test "pads UTC milliseconds to three digits" <|
                \() ->
                    { at = Time.millisToPosix 1
                    , actorUsername = "a"
                    , kind = WikiAuditLog.GrantedWikiAdmin { targetUsername = "x" }
                    }
                        |> WikiAuditLog.formatEventRowText
                        |> Expect.equal "1970-01-01 00:00:00.001 · a — Granted wiki admin to x"
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
