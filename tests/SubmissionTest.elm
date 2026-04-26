module SubmissionTest exposing (suite)

import ContributorAccount
import Dict
import Expect
import Fuzz
import Page
import Regex
import Submission
import Test exposing (Test)
import Wiki


pageSlugHtmlPatternRegex : Regex.Regex
pageSlugHtmlPatternRegex =
    "^("
        ++ Submission.pageSlugHtmlPattern
        ++ ")$"
        |> Regex.fromString
        |> Maybe.withDefault Regex.never


suite : Test
suite =
    Test.describe "Submission"
        [ Test.describe "validatePageSlug"
            [ Test.test "trims and validates PascalCase slug" <|
                \() ->
                    Submission.validatePageSlug "  MyPage1  "
                        |> Expect.equal (Ok "MyPage1")
            , Test.fuzz Fuzz.string "aligns with validateNewPageFields for any slug when body non-empty" <|
                \rawSlug ->
                    case Submission.validatePageSlug rawSlug of
                        Err e ->
                            Submission.validateNewPageFields rawSlug "x" ""
                                |> Expect.equal (Err e)

                        Ok slug ->
                            Submission.validateNewPageFields rawSlug "x" ""
                                |> Expect.equal (Ok { pageSlug = slug, markdown = "x", tags = [] })
            , Test.fuzz Fuzz.string "pageSlugHtmlPattern accepts every validatePageSlug Ok input" <|
                \raw ->
                    case Submission.validatePageSlug raw of
                        Ok _ ->
                            Regex.contains pageSlugHtmlPatternRegex raw
                                |> Expect.equal True

                        Err _ ->
                            Expect.pass
            ]
        , Test.describe "validateNewPageFields"
            [ Test.test "rejects empty slug" <|
                \() ->
                    Submission.validateNewPageFields "" "body" ""
                        |> Expect.equal (Err Submission.SlugEmpty)
            , Test.test "rejects whitespace-only slug" <|
                \() ->
                    Submission.validateNewPageFields " " "# Title" ""
                        |> Expect.equal (Err Submission.SlugEmpty)
            , Test.test "rejects slug longer than 64 chars" <|
                \() ->
                    Submission.validateNewPageFields (String.repeat 65 "a") "x" ""
                        |> Expect.equal (Err Submission.SlugTooLong)
            , Test.test "rejects invalid slug characters" <|
                \() ->
                    Submission.validateNewPageFields "bad slug" "x" ""
                        |> Expect.equal (Err Submission.SlugInvalidChars)
            , Test.test "rejects empty body" <|
                \() ->
                    Submission.validateNewPageFields "ValidSlug" "" ""
                        |> Expect.equal (Err Submission.BodyEmpty)
            , Test.test "rejects whitespace-only body" <|
                \() ->
                    Submission.validateNewPageFields "ValidSlug" "  \n\t " ""
                        |> Expect.equal (Err Submission.BodyEmpty)
            , Test.test "keeps trimmed PascalCase slug" <|
                \() ->
                    Submission.validateNewPageFields " MyPage1  " "# Hi" ""
                        |> Expect.equal (Ok { pageSlug = "MyPage1", markdown = "# Hi", tags = [] })
            , Test.fuzz Fuzz.string "body fuzz: empty trim fails" <|
                \s ->
                    if String.isEmpty (String.trim s) then
                        Submission.validateNewPageFields "ValidSlug" s ""
                            |> Expect.equal (Err Submission.BodyEmpty)

                    else
                        Submission.validateNewPageFields "ValidSlug" s ""
                            |> Result.map .markdown
                            |> Expect.equal (Ok (String.trim s))
            ]
        , Test.describe "pendingNewPageSlugInUse"
            [ Test.test "false on empty dict" <|
                \() ->
                    Submission.pendingNewPageSlugInUse "Demo" "x" Dict.empty
                        |> Expect.equal False
            , Test.test "true when pending new page matches slug" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "wanted"
                                    , markdown = "m"
                                    , tags = []
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugInUse "Demo" "wanted" (Dict.singleton "sub_1" sub)
                        |> Expect.equal True
            , Test.test "true when draft new page matches slug" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "wanted"
                                    , markdown = ""
                                    , tags = []
                                    }
                            , status = Submission.Draft
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugInUse "Demo" "wanted" (Dict.singleton "sub_1" sub)
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
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "aaa-fixed"
                                    , markdown = "m"
                                    , tags = []
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugInUse "Demo" candidate (Dict.singleton "sub_1" sub)
                        |> Expect.equal False
            , Test.test "false when pending submission is EditPage for same slug" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.EditPage
                                    { pageSlug = "guides"
                                    , baseMarkdown = "base"
                                    , baseRevision = 1
                                    , proposedMarkdown = "proposed"
                                    , tags = []
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugInUse "Demo" "guides" (Dict.singleton "sub_1" sub)
                        |> Expect.equal False
            , Test.test "false when pending submission is DeletePage for same slug" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.DeletePage
                                    { pageSlug = "guides"
                                    , reason = Just "bye"
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugInUse "Demo" "guides" (Dict.singleton "sub_1" sub)
                        |> Expect.equal False
            , Test.test "false when same slug exists only on rejected new page submission" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage { pageSlug = "wanted", markdown = "m", tags = [] }
                            , status = Submission.Rejected
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugInUse "Demo" "wanted" (Dict.singleton "sub_1" sub)
                        |> Expect.equal False
            ]
        , Test.describe "pendingNewPageSlugBlocksTrustedPublish"
            [ Test.test "false on empty dict" <|
                \() ->
                    Submission.pendingNewPageSlugBlocksTrustedPublish (ContributorAccount.newAccountId "Demo" "me") "Demo" "x" Dict.empty
                        |> Expect.equal False
            , Test.test "false when only the author's draft reserves the slug" <|
                \() ->
                    let
                        me : ContributorAccount.Id
                        me =
                            ContributorAccount.newAccountId "Demo" "me"

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = me
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "wanted"
                                    , markdown = ""
                                    , tags = []
                                    }
                            , status = Submission.Draft
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugBlocksTrustedPublish me "Demo" "wanted" (Dict.singleton "sub_1" sub)
                        |> Expect.equal False
            , Test.test "true when another author's draft reserves the slug" <|
                \() ->
                    let
                        me : ContributorAccount.Id
                        me =
                            ContributorAccount.newAccountId "Demo" "me"

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "other"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "wanted"
                                    , markdown = ""
                                    , tags = []
                                    }
                            , status = Submission.Draft
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugBlocksTrustedPublish me "Demo" "wanted" (Dict.singleton "sub_1" sub)
                        |> Expect.equal True
            , Test.test "true when pending new page reserves the slug (same author)" <|
                \() ->
                    let
                        me : ContributorAccount.Id
                        me =
                            ContributorAccount.newAccountId "Demo" "me"

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = me
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "wanted"
                                    , markdown = "m"
                                    , tags = []
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugBlocksTrustedPublish me "Demo" "wanted" (Dict.singleton "sub_1" sub)
                        |> Expect.equal True
            , Test.fuzz Fuzz.string "author's draft for slug never blocks that author alone" <|
                \suffix ->
                    let
                        slug : String
                        slug =
                            "Pg" ++ suffix

                        me : ContributorAccount.Id
                        me =
                            ContributorAccount.newAccountId "Demo" "me"

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = me
                            , kind =
                                Submission.NewPage
                                    { pageSlug = slug
                                    , markdown = ""
                                    , tags = []
                                    }
                            , status = Submission.Draft
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingNewPageSlugBlocksTrustedPublish me "Demo" slug (Dict.singleton "sub_1" sub)
                        |> Expect.equal False
            ]
        , Test.describe "removeAuthorDraftNewPageSubmissionsForSlug"
            [ Test.test "removes matching author draft new-page row" <|
                \() ->
                    let
                        me : ContributorAccount.Id
                        me =
                            ContributorAccount.newAccountId "Demo" "me"

                        draft : Submission.Submission
                        draft =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = me
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "wanted"
                                    , markdown = ""
                                    , tags = []
                                    }
                            , status = Submission.Draft
                            , reviewerNote = Nothing
                            }

                        other : Submission.Submission
                        other =
                            { id = Submission.idFromCounter 2
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "x"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "wanted"
                                    , markdown = ""
                                    , tags = []
                                    }
                            , status = Submission.Draft
                            , reviewerNote = Nothing
                            }
                    in
                    Dict.fromList [ ( "sub_1", draft ), ( "sub_2", other ) ]
                        |> Submission.removeAuthorDraftNewPageSubmissionsForSlug me "Demo" "wanted"
                        |> Dict.keys
                        |> Expect.equal [ "sub_2" ]
            , Test.fuzz Fuzz.string "does not remove when slug differs" <|
                \slugA ->
                    let
                        slugB : String
                        slugB =
                            slugA ++ "_other"

                        me : ContributorAccount.Id
                        me =
                            ContributorAccount.newAccountId "Demo" "me"

                        draft : Submission.Submission
                        draft =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = me
                            , kind =
                                Submission.NewPage
                                    { pageSlug = slugA
                                    , markdown = ""
                                    , tags = []
                                    }
                            , status = Submission.Draft
                            , reviewerNote = Nothing
                            }
                    in
                    Dict.singleton "sub_1" draft
                        |> Submission.removeAuthorDraftNewPageSubmissionsForSlug me "Demo" slugB
                        |> Dict.size
                        |> Expect.equal 1
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
        , Test.describe "validateDeleteReasonRequired"
            [ Test.test "empty string is rejected" <|
                \() ->
                    Submission.validateDeleteReasonRequired ""
                        |> Expect.equal (Err Submission.ReasonRequired)
            , Test.test "whitespace-only is rejected" <|
                \() ->
                    Submission.validateDeleteReasonRequired "  \n\t "
                        |> Expect.equal (Err Submission.ReasonRequired)
            , Test.test "trims non-empty reason" <|
                \() ->
                    Submission.validateDeleteReasonRequired "  obsolete  "
                        |> Expect.equal (Ok "obsolete")
            , Test.test "rejects reason longer than 2000 chars" <|
                \() ->
                    Submission.validateDeleteReasonRequired (String.repeat 2001 "x")
                        |> Expect.equal (Err Submission.ReasonTooLong)
            , Test.test "accepts reason of exactly 2000 chars" <|
                \() ->
                    Submission.validateDeleteReasonRequired (String.repeat 2000 "y")
                        |> Expect.equal (Ok (String.repeat 2000 "y"))
            ]
        , Test.describe "validateEditMarkdown"
            [ Test.test "rejects empty body" <|
                \() ->
                    Submission.validateEditMarkdown "" "" "Page"
                        |> Expect.equal (Err Submission.BodyEmpty)
            , Test.test "rejects whitespace-only body" <|
                \() ->
                    Submission.validateEditMarkdown "  \n\t " "" "Page"
                        |> Expect.equal (Err Submission.BodyEmpty)
            , Test.test "trims body" <|
                \() ->
                    Submission.validateEditMarkdown "  # Hi\n" "" "Page"
                        |> Expect.equal (Ok { proposedMarkdown = "# Hi", tags = [] })
            , Test.fuzz Fuzz.string "fuzz: empty trim fails" <|
                \s ->
                    if String.isEmpty (String.trim s) then
                        Submission.validateEditMarkdown s "" "Page"
                            |> Expect.equal (Err Submission.BodyEmpty)

                    else
                        Submission.validateEditMarkdown s "" "Page"
                            |> Expect.equal (Ok { proposedMarkdown = String.trim s, tags = [] })
            ]
        , Test.describe "wikiHasPublishedPage"
            [ Test.test "true for published page" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "Demo"
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
                            Wiki.wikiWithPages "Demo"
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
                            Wiki.wikiWithPages "Demo" "Demo" Dict.empty
                    in
                    Submission.wikiHasPublishedPage "nope" wiki
                        |> Expect.equal False
            , Test.fuzz Fuzz.string "false when slug not in wiki pages" <|
                \slug ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "Demo"
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
            , Test.test "DetailsWikiInactive" <|
                \() ->
                    Submission.detailsErrorToUserText Submission.DetailsWikiInactive
                        |> Expect.equal "This wiki is currently paused."
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
            , Test.test "Draft" <|
                \() ->
                    Submission.statusLabelUserText Submission.Draft
                        |> Expect.equal "Draft"
            ]
        , Test.describe "kindSummaryUserText"
            [ Test.test "NewPage" <|
                \() ->
                    Submission.kindSummaryUserText
                        (Submission.NewPage { pageSlug = "my-page", markdown = "x", tags = [] })
                        |> Expect.equal "New page: my-page"
            , Test.test "EditPage" <|
                \() ->
                    Submission.kindSummaryUserText
                        (Submission.EditPage { pageSlug = "home", baseMarkdown = "b", baseRevision = 1, proposedMarkdown = "x", tags = [] })
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
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage { pageSlug = "x", markdown = "m", tags = [] }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.contributorViewFromSubmission Nothing sub
                        |> Expect.equal
                            { id = Submission.idFromCounter 1
                            , status = Submission.Pending
                            , kindSummary = "New page: x"
                            , contributionKind = Submission.ContributorKindNewPage
                            , reviewerNote = Nothing
                            , conflictContext = Nothing
                            , compareOriginalMarkdown = "(No published page yet.)"
                            , compareNewMarkdown = "m"
                            , maybeNewPageSlug = Just "x"
                            , maybeEditPageSlug = Nothing
                            }
            , Test.test "maps reviewer note through reviewerNoteForDisplay" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 2
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.EditPage { pageSlug = "home", baseMarkdown = "old", baseRevision = 1, proposedMarkdown = "m", tags = [] }
                            , status = Submission.Rejected
                            , reviewerNote = Just "  not suitable  "
                            }
                    in
                    Submission.contributorViewFromSubmission Nothing sub
                        |> Expect.equal
                            { id = Submission.idFromCounter 2
                            , status = Submission.Rejected
                            , kindSummary = "Edit page: home"
                            , contributionKind = Submission.ContributorKindEditPage
                            , reviewerNote = Just "not suitable"
                            , conflictContext =
                                Just
                                    { pageSlug = "home"
                                    , baseMarkdown = "old"
                                    , baseRevision = 1
                                    , proposedMarkdown = "m"
                                    , currentMarkdown = "old"
                                    , currentRevision = 1
                                    }
                            , compareOriginalMarkdown = "old"
                            , compareNewMarkdown = "m"
                            , maybeNewPageSlug = Nothing
                            , maybeEditPageSlug = Just "home"
                            }
            ]
        , Test.describe "pendingSubmissionsForWiki"
            [ Test.test "empty dict yields empty list" <|
                \() ->
                    Submission.pendingSubmissionsForWiki "Demo" Dict.empty
                        |> Expect.equal []
            , Test.test "filters wiki and pending, sorted by id string" <|
                \() ->
                    let
                        pendingDemo1 : Submission.Submission
                        pendingDemo1 =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "a"
                            , kind =
                                Submission.NewPage { pageSlug = "x", markdown = "m", tags = [] }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }

                        pendingDemo2 : Submission.Submission
                        pendingDemo2 =
                            { id = Submission.idFromCounter 2
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "b"
                            , kind =
                                Submission.EditPage { pageSlug = "home", baseMarkdown = "old", baseRevision = 1, proposedMarkdown = "m", tags = [] }
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
                        |> Submission.pendingSubmissionsForWiki "Demo"
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
        , Test.describe "mySubmissionsForAuthorOnWiki"
            [ Test.test "filters wiki listed statuses and author, sorted by id string" <|
                \() ->
                    let
                        author : ContributorAccount.Id
                        author =
                            ContributorAccount.newAccountId "Demo" "demo_contributor"

                        otherAuthor : ContributorAccount.Id
                        otherAuthor =
                            ContributorAccount.newAccountId "Demo" "other"

                        mine1 : Submission.Submission
                        mine1 =
                            { id = Submission.idFromKey "sub_b"
                            , wikiSlug = "Demo"
                            , authorId = author
                            , kind =
                                Submission.NewPage { pageSlug = "B", markdown = "m", tags = [] }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }

                        mine2 : Submission.Submission
                        mine2 =
                            { id = Submission.idFromKey "sub_a"
                            , wikiSlug = "Demo"
                            , authorId = author
                            , kind =
                                Submission.NewPage { pageSlug = "A", markdown = "m", tags = [] }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }

                        notMine : Submission.Submission
                        notMine =
                            { mine1 | authorId = otherAuthor }

                        approvedMine : Submission.Submission
                        approvedMine =
                            { mine1 | status = Submission.Approved }

                        rejectedMine : Submission.Submission
                        rejectedMine =
                            { mine1 | id = Submission.idFromKey "sub_r", status = Submission.Rejected }
                    in
                    [ ( "sub_b", mine1 ), ( "sub_a", mine2 ), ( "o", notMine ), ( "ap", approvedMine ), ( "sub_r", rejectedMine ) ]
                        |> Dict.fromList
                        |> Submission.mySubmissionsForAuthorOnWiki "Demo" author
                        |> Expect.equal [ mine2, mine1, rejectedMine ]
            , Test.fuzz Fuzz.string "returns pending and needs-revision for matching wiki and author" <|
                \noise ->
                    let
                        wikiSlug : Wiki.Slug
                        wikiSlug =
                            "w" ++ noise

                        author : ContributorAccount.Id
                        author =
                            ContributorAccount.newAccountId wikiSlug "u"

                        other : ContributorAccount.Id
                        other =
                            ContributorAccount.newAccountId wikiSlug "v"

                        pendingMine : Submission.Submission
                        pendingMine =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = wikiSlug
                            , authorId = author
                            , kind =
                                Submission.DeletePage { pageSlug = "p", reason = Nothing }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }

                        wrongAuthor : Submission.Submission
                        wrongAuthor =
                            { pendingMine | authorId = other }

                        needsRevMine : Submission.Submission
                        needsRevMine =
                            { pendingMine | id = Submission.idFromCounter 2, status = Submission.NeedsRevision }
                    in
                    [ ( "a", pendingMine ), ( "b", wrongAuthor ), ( "c", needsRevMine ) ]
                        |> Dict.fromList
                        |> Submission.mySubmissionsForAuthorOnWiki wikiSlug author
                        |> Expect.equal [ pendingMine, needsRevMine ]
            ]
        , Test.describe "myPendingSubmissionListItemFromSubmission"
            [ Test.test "maps id kind and page slug" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 5
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage { pageSlug = "MyPage", markdown = "m", tags = [] }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.myPendingSubmissionListItemFromSubmission sub
                        |> Expect.equal
                            { id = Submission.idFromCounter 5
                            , status = Submission.Pending
                            , statusLabel = "Pending review"
                            , kindLabel = "New page: MyPage"
                            , maybePageSlug = Just "MyPage"
                            }
            ]
        , Test.describe "pendingEditForAuthorOnPageInUse"
            [ Test.test "true only for pending edit by same author on same page" <|
                \() ->
                    let
                        author : ContributorAccount.Id
                        author =
                            ContributorAccount.newAccountId "Demo" "a"

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = author
                            , kind =
                                Submission.EditPage { pageSlug = "home", baseMarkdown = "old", baseRevision = 1, proposedMarkdown = "new", tags = [] }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.pendingEditForAuthorOnPageInUse "Demo" author "home" (Dict.singleton "sub_1" sub)
                        |> Expect.equal True
            , Test.fuzz Fuzz.string "non-pending edit does not count" <|
                \suffix ->
                    let
                        author : ContributorAccount.Id
                        author =
                            ContributorAccount.newAccountId "Demo" "a"
                    in
                    Submission.pendingEditForAuthorOnPageInUse
                        "Demo"
                        author
                        ("home" ++ suffix)
                        (Dict.singleton
                            "sub_1"
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = author
                            , kind =
                                Submission.EditPage { pageSlug = "home", baseMarkdown = "old", baseRevision = 1, proposedMarkdown = "new", tags = [] }
                            , status = Submission.Rejected
                            , reviewerNote = Nothing
                            }
                        )
                        |> Expect.equal False
            ]
        , Test.describe "isStalePendingEditSubmission"
            [ Test.test "true when base revision differs from current" <|
                \() ->
                    Submission.isStalePendingEditSubmission
                        { pageSlug = "home", currentRevision = 2 }
                        { id = Submission.idFromCounter 1
                        , wikiSlug = "Demo"
                        , authorId = ContributorAccount.newAccountId "Demo" "u"
                        , kind =
                            Submission.EditPage { pageSlug = "home", baseMarkdown = "old", baseRevision = 1, proposedMarkdown = "new", tags = [] }
                        , status = Submission.Pending
                        , reviewerNote = Nothing
                        }
                        |> Expect.equal True
            , Test.test "false when revision matches" <|
                \() ->
                    Submission.isStalePendingEditSubmission
                        { pageSlug = "home", currentRevision = 1 }
                        { id = Submission.idFromCounter 1
                        , wikiSlug = "Demo"
                        , authorId = ContributorAccount.newAccountId "Demo" "u"
                        , kind =
                            Submission.EditPage { pageSlug = "home", baseMarkdown = "old", baseRevision = 1, proposedMarkdown = "new", tags = [] }
                        , status = Submission.Pending
                        , reviewerNote = Nothing
                        }
                        |> Expect.equal False
            ]
        , Test.describe "withdrawSubmissionToDraft"
            [ Test.test "Pending to Draft" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage { pageSlug = "Pg", markdown = "m", tags = [] }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.withdrawSubmissionToDraft sub
                        |> Result.map .status
                        |> Expect.equal (Ok Submission.Draft)
            , Test.test "rejects Draft" <|
                \() ->
                    let
                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage { pageSlug = "Pg", markdown = "m", tags = [] }
                            , status = Submission.Draft
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.withdrawSubmissionToDraft sub
                        |> Expect.equal (Err Submission.WithdrawSubmissionNotPendingOrNeedsRevision)
            ]
        , Test.describe "promoteDraftToPending"
            [ Test.test "rebases edit draft on current published wiki" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "Demo"
                                "Demo"
                                (Dict.singleton "home" (Page.withPublished "home" "current-live"))

                        author : ContributorAccount.Id
                        author =
                            ContributorAccount.newAccountId "Demo" "u"

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = author
                            , kind =
                                Submission.EditPage
                                    { pageSlug = "home"
                                    , baseMarkdown = "stale-base"
                                    , baseRevision = 1
                                    , proposedMarkdown = "  my-edit \n"
                                    , tags = []
                                    }
                            , status = Submission.Draft
                            , reviewerNote = Just "old note"
                            }
                    in
                    Submission.promoteDraftToPending wiki Dict.empty sub
                        |> Expect.equal
                            (Ok
                                { id = Submission.idFromCounter 1
                                , wikiSlug = "Demo"
                                , authorId = author
                                , status = Submission.Pending
                                , reviewerNote = Nothing
                                , kind =
                                    Submission.EditPage
                                        { pageSlug = "home"
                                        , baseMarkdown = "current-live"
                                        , baseRevision = 1
                                        , proposedMarkdown = "my-edit"
                                        , tags = []
                                        }
                                }
                            )
            , Test.test "DeletePage draft requires non-empty reason" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "Demo"
                                "Demo"
                                (Dict.singleton "home" (Page.withPublished "home" "live"))

                        author : ContributorAccount.Id
                        author =
                            ContributorAccount.newAccountId "Demo" "u"

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 2
                            , wikiSlug = "Demo"
                            , authorId = author
                            , kind =
                                Submission.DeletePage
                                    { pageSlug = "home"
                                    , reason = Nothing
                                    }
                            , status = Submission.Draft
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.promoteDraftToPending wiki Dict.empty sub
                        |> Expect.equal (Err (Submission.SubmitDraftForReviewDeleteReasonInvalid Submission.ReasonRequired))
            , Test.test "DeletePage draft promotes with trimmed reason" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "Demo"
                                "Demo"
                                (Dict.singleton "home" (Page.withPublished "home" "live"))

                        author : ContributorAccount.Id
                        author =
                            ContributorAccount.newAccountId "Demo" "u"

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 3
                            , wikiSlug = "Demo"
                            , authorId = author
                            , kind =
                                Submission.DeletePage
                                    { pageSlug = "home"
                                    , reason = Just "  bye  "
                                    }
                            , status = Submission.Draft
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.promoteDraftToPending wiki Dict.empty sub
                        |> Expect.equal
                            (Ok
                                { id = Submission.idFromCounter 3
                                , wikiSlug = "Demo"
                                , authorId = author
                                , status = Submission.Pending
                                , reviewerNote = Nothing
                                , kind =
                                    Submission.DeletePage
                                        { pageSlug = "home"
                                        , reason = Just "bye"
                                        }
                                }
                            )
            ]
        , Test.describe "pageSlugFromKind"
            [ Test.test "NewPage" <|
                \() ->
                    Submission.pageSlugFromKind (Submission.NewPage { pageSlug = "a", markdown = "m", tags = [] })
                        |> Expect.equal (Just "a")
            , Test.test "EditPage" <|
                \() ->
                    Submission.pageSlugFromKind (Submission.EditPage { pageSlug = "b", baseMarkdown = "old", baseRevision = 1, proposedMarkdown = "m", tags = [] })
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
                            ContributorAccount.newAccountId "Demo" "alice"

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_x"
                            , wikiSlug = "Demo"
                            , authorId = accountId
                            , kind =
                                Submission.NewPage { pageSlug = "pg", markdown = "m", tags = [] }
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
                            ContributorAccount.newAccountId "Demo" "bob"

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromCounter 1
                            , wikiSlug = "Demo"
                            , authorId = accountId
                            , kind =
                                Submission.EditPage { pageSlug = "h", baseMarkdown = "old", baseRevision = 1, proposedMarkdown = "m", tags = [] }
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
                            Wiki.wikiWithPages "Demo" "Demo" Dict.empty

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_queue_demo"
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "QueueDemoPage"
                                    , markdown = "Body text"
                                    , tags = []
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
                                , Dict.member "QueueDemoPage" r.wiki.pages
                                )
                            )
                        |> Expect.equal (Ok ( Submission.Approved, Nothing, True ))
            , Test.test "rejects when submission is not pending" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "Demo" "Demo" Dict.empty

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_1"
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "x", markdown = "m", tags = [] }
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
                            Wiki.wikiWithPages "Demo"
                                "Demo"
                                (Dict.singleton "QueueDemoPage" (Page.withPublished "QueueDemoPage" "old"))

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_1"
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "QueueDemoPage"
                                    , markdown = "new"
                                    , tags = []
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
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "QueueDemoPage"
                                    , markdown = "Body text"
                                    , tags = []
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
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "x", markdown = "m", tags = [] }
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
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "x-page"
                                    , markdown = "Body"
                                    , tags = []
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
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "x", markdown = "m", tags = [] }
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
                            , wikiSlug = "Demo"
                            , authorId = ContributorAccount.newAccountId "Demo" "u"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "x", markdown = "m", tags = [] }
                            , status = Submission.Approved
                            , reviewerNote = Nothing
                            }
                    in
                    Submission.requestPendingSubmissionChanges "please revise" sub
                        |> Expect.equal (Err Submission.RequestChangesNotPending)
            ]
        ]
