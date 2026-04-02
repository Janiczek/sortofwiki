module SubmissionTest exposing (suite)

import ContributorAccount
import Dict
import Expect
import Fuzz
import Page
import Submission
import Test exposing (Test)
import Wiki


suite : Test
suite =
    Test.describe "Submission"
        [ Test.describe "validatePageSlug"
            [ Test.test "normalizes like new-page slug" <|
                \() ->
                    Submission.validatePageSlug "  MyPage-1  "
                        |> Expect.equal (Ok "mypage-1")
            , Test.fuzz Fuzz.string "aligns with validateNewPageFields for any slug when body non-empty" <|
                \rawSlug ->
                    case Submission.validatePageSlug rawSlug of
                        Err e ->
                            Submission.validateNewPageFields rawSlug "x"
                                |> Expect.equal (Err e)

                        Ok slug ->
                            Submission.validateNewPageFields rawSlug "x"
                                |> Expect.equal (Ok { pageSlug = slug, markdown = "x" })
            ]
        , Test.describe "validateNewPageFields"
            [ Test.test "rejects empty slug" <|
                \() ->
                    Submission.validateNewPageFields "" "body"
                        |> Expect.equal (Err Submission.SlugEmpty)
            , Test.test "rejects whitespace-only slug" <|
                \() ->
                    Submission.validateNewPageFields "   " "# Title"
                        |> Expect.equal (Err Submission.SlugEmpty)
            , Test.test "rejects slug longer than 64 chars" <|
                \() ->
                    Submission.validateNewPageFields (String.repeat 65 "a") "x"
                        |> Expect.equal (Err Submission.SlugTooLong)
            , Test.test "rejects invalid slug characters" <|
                \() ->
                    Submission.validateNewPageFields "bad slug" "x"
                        |> Expect.equal (Err Submission.SlugInvalidChars)
            , Test.test "rejects empty body" <|
                \() ->
                    Submission.validateNewPageFields "ok" ""
                        |> Expect.equal (Err Submission.BodyEmpty)
            , Test.test "rejects whitespace-only body" <|
                \() ->
                    Submission.validateNewPageFields "ok" "  \n\t "
                        |> Expect.equal (Err Submission.BodyEmpty)
            , Test.test "normalizes slug to trimmed lowercase" <|
                \() ->
                    Submission.validateNewPageFields "  MyPage-1  " "# Hi"
                        |> Expect.equal (Ok { pageSlug = "mypage-1", markdown = "# Hi" })
            , Test.fuzz Fuzz.string "body fuzz: empty trim fails" <|
                \s ->
                    if String.isEmpty (String.trim s) then
                        Submission.validateNewPageFields "validslug" s
                            |> Expect.equal (Err Submission.BodyEmpty)

                    else
                        Submission.validateNewPageFields "validslug" s
                            |> Result.map .markdown
                            |> Expect.equal (Ok (String.trim s))
            ]
        , Test.describe "pendingNewPageSlugInUse"
            [ Test.test "false on empty dict" <|
                \() ->
                    Submission.pendingNewPageSlugInUse "demo" "x" Dict.empty
                        |> Expect.equal False
            , Test.test "true when pending new page matches slug" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "wanted"
                                    , markdown = "m"
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugInUse "demo" "wanted" (Dict.singleton "sub_1" sub)
                        |> Expect.equal True
            , Test.fuzz Fuzz.string "false when slug differs from pending new page" <|
                \suffix ->
                    let
                        candidate : String
                        candidate =
                            "zzz" ++ suffix

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "aaa-fixed"
                                    , markdown = "m"
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugInUse "demo" candidate (Dict.singleton "sub_1" sub)
                        |> Expect.equal False
            , Test.test "false when pending submission is EditPage for same slug" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.EditPage
                                    { pageSlug = "guides"
                                    , markdown = "proposed"
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugInUse "demo" "guides" (Dict.singleton "sub_1" sub)
                        |> Expect.equal False
            , Test.test "false when pending submission is DeletePage for same slug" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.DeletePage
                                    { pageSlug = "guides"
                                    , reason = Just "bye"
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugInUse "demo" "guides" (Dict.singleton "sub_1" sub)
                        |> Expect.equal False
            , Test.test "false when same slug exists only on rejected new page submission" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.NewPage { pageSlug = "wanted", markdown = "m" }
                            , status = Submission.Rejected
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugInUse "demo" "wanted" (Dict.singleton "sub_1" sub)
                        |> Expect.equal False
            ]
        , Test.describe "validateDeleteReason"
            [ Test.test "empty string is Nothing" <|
                \() ->
                    Submission.validateDeleteReason ""
                        |> Expect.equal (Ok Nothing)
            , Test.test "whitespace-only is Nothing" <|
                \() ->
                    Submission.validateDeleteReason "  \n\t "
                        |> Expect.equal (Ok Nothing)
            , Test.test "trims non-empty reason" <|
                \() ->
                    Submission.validateDeleteReason "  duplicate  "
                        |> Expect.equal (Ok (Just "duplicate"))
            , Test.test "rejects reason longer than 2000 chars" <|
                \() ->
                    Submission.validateDeleteReason (String.repeat 2001 "x")
                        |> Expect.equal (Err Submission.ReasonTooLong)
            , Test.test "accepts reason of exactly 2000 chars" <|
                \() ->
                    Submission.validateDeleteReason (String.repeat 2000 "y")
                        |> Expect.equal (Ok (Just (String.repeat 2000 "y")))
            , Test.fuzz Fuzz.string "empty trim yields Nothing" <|
                \s ->
                    if String.isEmpty (String.trim s) then
                        Submission.validateDeleteReason s
                            |> Expect.equal (Ok Nothing)

                    else if String.length (String.trim s) > 2000 then
                        Submission.validateDeleteReason s
                            |> Expect.equal (Err Submission.ReasonTooLong)

                    else
                        Submission.validateDeleteReason s
                            |> Expect.equal (Ok (Just (String.trim s)))
            ]
        , Test.describe "validateEditMarkdown"
            [ Test.test "rejects empty body" <|
                \() ->
                    Submission.validateEditMarkdown ""
                        |> Expect.equal (Err Submission.BodyEmpty)
            , Test.test "rejects whitespace-only body" <|
                \() ->
                    Submission.validateEditMarkdown "  \n\t "
                        |> Expect.equal (Err Submission.BodyEmpty)
            , Test.test "trims body" <|
                \() ->
                    Submission.validateEditMarkdown "  # Hi\n"
                        |> Expect.equal (Ok "# Hi")
            , Test.fuzz Fuzz.string "fuzz: empty trim fails" <|
                \s ->
                    if String.isEmpty (String.trim s) then
                        Submission.validateEditMarkdown s
                            |> Expect.equal (Err Submission.BodyEmpty)

                    else
                        Submission.validateEditMarkdown s
                            |> Expect.equal (Ok (String.trim s))
            ]
        , Test.describe "wikiHasPublishedPage"
            [ Test.test "true for published page" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "demo"
                                "Demo"
                                (Dict.singleton "home" (Page.withPublished "home" "# H"))
                    in
                    Submission.wikiHasPublishedPage "home" wiki
                        |> Expect.equal True
            , Test.test "false for pending-only page" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "demo"
                                "Demo"
                                (Dict.singleton "draft" (Page.pendingOnly "draft" "secret"))
                    in
                    Submission.wikiHasPublishedPage "draft" wiki
                        |> Expect.equal False
            , Test.test "false for missing slug" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "demo" "Demo" Dict.empty
                    in
                    Submission.wikiHasPublishedPage "nope" wiki
                        |> Expect.equal False
            , Test.fuzz Fuzz.string "false when slug not in wiki pages" <|
                \slug ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "demo"
                                "Demo"
                                (Dict.singleton "fixed" (Page.withPublished "fixed" "x"))
                    in
                    if Dict.member slug wiki.pages then
                        Expect.pass

                    else
                        Submission.wikiHasPublishedPage slug wiki
                            |> Expect.equal False
            ]
        , Test.describe "detailsErrorToUserText"
            [ Test.test "DetailsNotLoggedIn" <|
                \() ->
                    Submission.detailsErrorToUserText Submission.DetailsNotLoggedIn
                        |> Expect.equal "Log in on this wiki to view this submission."
            , Test.test "DetailsWrongWikiSession" <|
                \() ->
                    Submission.detailsErrorToUserText Submission.DetailsWrongWikiSession
                        |> Expect.equal "Your session is for a different wiki. Log in again on this wiki."
            , Test.test "DetailsNotFound" <|
                \() ->
                    Submission.detailsErrorToUserText Submission.DetailsNotFound
                        |> Expect.equal "That submission was not found."
            , Test.test "DetailsForbidden" <|
                \() ->
                    Submission.detailsErrorToUserText Submission.DetailsForbidden
                        |> Expect.equal "You cannot view this submission."
            ]
        , Test.describe "statusLabelUserText"
            [ Test.test "Pending" <|
                \() ->
                    Submission.statusLabelUserText Submission.Pending
                        |> Expect.equal "Pending review"
            , Test.test "Approved" <|
                \() ->
                    Submission.statusLabelUserText Submission.Approved
                        |> Expect.equal "Approved"
            , Test.test "Rejected" <|
                \() ->
                    Submission.statusLabelUserText Submission.Rejected
                        |> Expect.equal "Rejected"
            , Test.test "NeedsRevision" <|
                \() ->
                    Submission.statusLabelUserText Submission.NeedsRevision
                        |> Expect.equal "Needs revision"
            ]
        , Test.describe "kindSummaryUserText"
            [ Test.test "NewPage" <|
                \() ->
                    Submission.kindSummaryUserText
                        (Submission.NewPage { pageSlug = "my-page", markdown = "x" })
                        |> Expect.equal "New page: my-page"
            , Test.test "EditPage" <|
                \() ->
                    Submission.kindSummaryUserText
                        (Submission.EditPage { pageSlug = "home", markdown = "x" })
                        |> Expect.equal "Edit page: home"
            , Test.test "DeletePage" <|
                \() ->
                    Submission.kindSummaryUserText
                        (Submission.DeletePage { pageSlug = "old", reason = Just "dup" })
                        |> Expect.equal "Delete page: old"
            ]
        , Test.describe "reviewerNoteForDisplay"
            [ Test.test "Nothing stays Nothing" <|
                \() ->
                    Submission.reviewerNoteForDisplay Nothing
                        |> Expect.equal Nothing
            , Test.test "trims and keeps non-empty" <|
                \() ->
                    Submission.reviewerNoteForDisplay (Just "  fix typos  ")
                        |> Expect.equal (Just "fix typos")
            , Test.test "whitespace-only becomes Nothing" <|
                \() ->
                    Submission.reviewerNoteForDisplay (Just "  \n\t ")
                        |> Expect.equal Nothing
            , Test.test "empty string becomes Nothing" <|
                \() ->
                    Submission.reviewerNoteForDisplay (Just "")
                        |> Expect.equal Nothing
            ]
        , Test.describe "contributorViewFromSubmission"
            [ Test.test "maps kind to summary" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.NewPage { pageSlug = "x", markdown = "m" }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.contributorViewFromSubmission sub
                        |> Expect.equal
                            { id = Submission.idFromCounter 1
                            , status = Submission.Pending
                            , kindSummary = "New page: x"
                            , reviewerNote = Nothing
                            }
            , Test.test "maps reviewer note through reviewerNoteForDisplay" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 2
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.EditPage { pageSlug = "home", markdown = "m" }
                            , status = Submission.Rejected
                            , reviewerNote = Just "  not suitable  "
                            }
                    in
                    Submission.contributorViewFromSubmission sub
                        |> Expect.equal
                            { id = Submission.idFromCounter 2
                            , status = Submission.Rejected
                            , kindSummary = "Edit page: home"
                            , reviewerNote = Just "not suitable"
                            }
            ]
        , Test.describe "pendingSubmissionsForWiki"
            [ Test.test "empty dict yields empty list" <|
                \() ->
                    Submission.pendingSubmissionsForWiki "demo" Dict.empty
                        |> Expect.equal []
            , Test.test "filters wiki and pending, sorted by id string" <|
                \() ->
                    let
                        pendingDemo1 : Submission.Submission
                        pendingDemo1 =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "a"
                            , kind =
                                Submission.NewPage { pageSlug = "x", markdown = "m" }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }

                        pendingDemo2 : Submission.Submission
                        pendingDemo2 =
                            { id = Submission.idFromCounter 2
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "b"
                            , kind =
                                Submission.EditPage { pageSlug = "home", markdown = "m" }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }

                        approved : Submission.Submission
                        approved =
                            { pendingDemo1 | status = Submission.Approved }

                        otherWiki : Submission.Submission
                        otherWiki =
                            { pendingDemo1 | wikiSlug = "other" }
                    in
                    [ ( "sub_1", pendingDemo1 )
                    , ( "sub_2", pendingDemo2 )
                    , ( "sub_ap", approved )
                    , ( "sub_o", otherWiki )
                    ]
                        |> Dict.fromList
                        |> Submission.pendingSubmissionsForWiki "demo"
                        |> Expect.equal [ pendingDemo1, pendingDemo2 ]
            , Test.fuzz Fuzz.string "only returns pending for matching wiki" <|
                \noise ->
                    let
                        wikiSlug : Wiki.Slug
                        wikiSlug =
                            "w" ++ noise

                        pending : Submission.Submission
                        pending =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = wikiSlug
                            , authorId = ContributorAccount.newAccountId wikiSlug "u"
                            , kind =
                                Submission.DeletePage { pageSlug = "p", reason = Nothing }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }

                        wrongWiki : Submission.Submission
                        wrongWiki =
                            { pending | wikiSlug = wikiSlug ++ "x" }

                        notPending : Submission.Submission
                        notPending =
                            { pending | status = Submission.Rejected }
                    in
                    [ ( "a", pending ), ( "b", wrongWiki ), ( "c", notPending ) ]
                        |> Dict.fromList
                        |> Submission.pendingSubmissionsForWiki wikiSlug
                        |> Expect.equal [ pending ]
            ]
        , Test.describe "pageSlugFromKind"
            [ Test.test "NewPage" <|
                \() ->
                    Submission.pageSlugFromKind (Submission.NewPage { pageSlug = "a", markdown = "m" })
                        |> Expect.equal (Just "a")
            , Test.test "EditPage" <|
                \() ->
                    Submission.pageSlugFromKind (Submission.EditPage { pageSlug = "b", markdown = "m" })
                        |> Expect.equal (Just "b")
            , Test.test "DeletePage" <|
                \() ->
                    Submission.pageSlugFromKind (Submission.DeletePage { pageSlug = "c", reason = Nothing })
                        |> Expect.equal (Just "c")
            ]
        , Test.describe "reviewQueueItemFromSubmission"
            [ Test.test "uses lookup for author display" <|
                \() ->
                    let
                        accountId : ContributorAccount.Id
                        accountId =
                            ContributorAccount.newAccountId "demo" "alice"

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_x"
                            , wikiSlug = "demo"
                            , authorId = accountId
                            , kind =
                                Submission.NewPage { pageSlug = "pg", markdown = "m" }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }

                        lookup : ContributorAccount.Id -> Maybe String
                        lookup aid =
                            if aid == accountId then
                                Just "alice"

                            else
                                Nothing
                    in
                    Submission.reviewQueueItemFromSubmission lookup sub
                        |> Expect.equal
                            { id = Submission.idFromKey "sub_x"
                            , kindLabel = "New page: pg"
                            , authorDisplay = "alice"
                            , maybePageSlug = Just "pg"
                            }
            , Test.test "falls back to id string when lookup misses" <|
                \() ->
                    let
                        accountId : ContributorAccount.Id
                        accountId =
                            ContributorAccount.newAccountId "demo" "bob"

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "demo"
                            , authorId = accountId
                            , kind =
                                Submission.EditPage { pageSlug = "h", markdown = "m" }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.reviewQueueItemFromSubmission (always Nothing) sub
                        |> Expect.equal
                            { id = Submission.idFromCounter 1
                            , kindLabel = "Edit page: h"
                            , authorDisplay = ContributorAccount.idToString accountId
                            , maybePageSlug = Just "h"
                            }
            ]
        , Test.describe "applyApprovedSubmission"
            [ Test.test "pending new page publishes and marks approved" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "demo" "Demo" Dict.empty

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_queue_demo"
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "queue-demo-page"
                                    , markdown = "Body text"
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Just "draft note"
                            }
                    in
                    Submission.applyApprovedSubmission wiki sub
                        |> Result.map
                            (\r ->
                                ( r.submission.status
                                , r.submission.reviewerNote
                                , Dict.member "queue-demo-page" r.wiki.pages
                                )
                            )
                        |> Expect.equal (Ok ( Submission.Approved, Nothing, True ))
            , Test.test "rejects when submission is not pending" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "demo" "Demo" Dict.empty

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_1"
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "x", markdown = "m" }
                            , status = Submission.Rejected
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.applyApprovedSubmission wiki sub
                        |> Expect.equal (Err Submission.ApproveNotPending)
            , Test.test "rejects new page when slug already has a page" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "demo"
                                "Demo"
                                (Dict.singleton "queue-demo-page" (Page.withPublished "queue-demo-page" "old"))

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_1"
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "queue-demo-page"
                                    , markdown = "new"
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.applyApprovedSubmission wiki sub
                        |> Expect.equal (Err Submission.ApproveNewPageSlugTaken)
            ]
        , Test.describe "validateRejectReason"
            [ Test.test "rejects empty string" <|
                \() ->
                    Submission.validateRejectReason ""
                        |> Expect.equal (Err Submission.RejectReasonEmpty)
            , Test.test "rejects whitespace-only" <|
                \() ->
                    Submission.validateRejectReason "  \n\t "
                        |> Expect.equal (Err Submission.RejectReasonEmpty)
            , Test.test "rejects over max length" <|
                \() ->
                    Submission.validateRejectReason (String.repeat 2001 "a")
                        |> Expect.equal (Err Submission.RejectReasonTooLong)
            , Test.test "accepts trimmed non-empty" <|
                \() ->
                    Submission.validateRejectReason "  not harmful, just low quality  "
                        |> Expect.equal (Ok "not harmful, just low quality")
            , Test.fuzz Fuzz.string "empty trim fails" <|
                \s ->
                    if String.isEmpty (String.trim s) then
                        Submission.validateRejectReason s
                            |> Expect.equal (Err Submission.RejectReasonEmpty)

                    else if String.length (String.trim s) > Submission.rejectReasonMaxLength then
                        Submission.validateRejectReason s
                            |> Expect.equal (Err Submission.RejectReasonTooLong)

                    else
                        Submission.validateRejectReason s
                            |> Expect.equal (Ok (String.trim s))
            ]
        , Test.describe "rejectPendingSubmission"
            [ Test.test "marks pending rejected with note" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_queue_demo"
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "queue-demo-page"
                                    , markdown = "Body text"
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.rejectPendingSubmission "  reason  " sub
                        |> Expect.equal
                            (Ok
                                { sub
                                    | status = Submission.Rejected
                                    , reviewerNote = Just "reason"
                                }
                            )
            , Test.test "fails when not pending" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_1"
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "x", markdown = "m" }
                            , status = Submission.Approved
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.rejectPendingSubmission "no" sub
                        |> Expect.equal (Err Submission.RejectNotPending)
            ]
        , Test.describe "requestPendingSubmissionChanges"
            [ Test.test "marks pending as NeedsRevision with guidance" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_changes_demo"
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "x-page"
                                    , markdown = "Body"
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.requestPendingSubmissionChanges "  iterate on this  " sub
                        |> Expect.equal
                            (Ok
                                { sub
                                    | status = Submission.NeedsRevision
                                    , reviewerNote = Just "iterate on this"
                                }
                            )
            , Test.test "fails when guidance empty after trim" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_1"
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "x", markdown = "m" }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.requestPendingSubmissionChanges "  \t  " sub
                        |> Expect.equal (Err (Submission.RequestChangesGuidanceInvalid Submission.RejectReasonEmpty))
            , Test.test "fails when not pending" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_1"
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "x", markdown = "m" }
                            , status = Submission.Approved
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.requestPendingSubmissionChanges "please revise" sub
                        |> Expect.equal (Err Submission.RequestChangesNotPending)
            ]
        ]
