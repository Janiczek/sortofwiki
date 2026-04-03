module SubmissionReviewDetailTest exposing (suite)

import ContributorAccount
import Dict
import Expect
import Page
import Submission
import SubmissionReviewDetail
import Test exposing (Test)
import Wiki


suite : Test
suite =
    Test.describe "SubmissionReviewDetail"
        [ Test.describe "reviewDetailFromWikiAndSubmission"
            [ Test.test "NewPageDiff carries proposed markdown (no published page yet)" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "demo" "Demo" Dict.empty

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_queue_demo"
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "statusdemo"
                            , kind =
                                Submission.NewPage
                                    { pageSlug = "QueueDemoPage"
                                    , markdown = "Seeded pending submission for the trusted review queue (story 15)."
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    SubmissionReviewDetail.reviewDetailFromWikiAndSubmission wiki sub
                        |> Expect.equal
                            (SubmissionReviewDetail.NewPageDiff
                                { pageSlug = "QueueDemoPage"
                                , proposedMarkdown = "Seeded pending submission for the trusted review queue (story 15)."
                                }
                            )
            , Test.test "EditPageDiff uses published markdown as before and submission body as after" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "demo"
                                "Demo"
                                (Dict.singleton "home"
                                    (Page.withPublished "home" "## Published\n\nOriginal.")
                                )

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_edit_demo"
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "statusdemo"
                            , kind =
                                Submission.EditPage
                                    { pageSlug = "home"
                                    , baseMarkdown = "## Published\n\nOriginal."
                                    , baseRevision = 1
                                    , proposedMarkdown = "## Proposed\n\nReplacement."
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    SubmissionReviewDetail.reviewDetailFromWikiAndSubmission wiki sub
                        |> Expect.equal
                            (SubmissionReviewDetail.EditPageDiff
                                { pageSlug = "home"
                                , beforeMarkdown = "## Published\n\nOriginal."
                                , afterMarkdown = "## Proposed\n\nReplacement."
                                }
                            )
            , Test.test "DeletePageDiff shows published snapshot and optional reason" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "demo"
                                "Demo"
                                (Dict.singleton "guides"
                                    (Page.withPublished "guides" "Guide body.")
                                )

                        sub : Submission.Submission
                        sub =
                            { id = Submission.idFromKey "sub_del_demo"
                            , wikiSlug = "demo"
                            , authorId = ContributorAccount.newAccountId "demo" "statusdemo"
                            , kind =
                                Submission.DeletePage
                                    { pageSlug = "guides"
                                    , reason = Just "Outdated."
                                    }
                            , status = Submission.Pending
                            , reviewerNote = Nothing
                            }
                    in
                    SubmissionReviewDetail.reviewDetailFromWikiAndSubmission wiki sub
                        |> Expect.equal
                            (SubmissionReviewDetail.DeletePageDiff
                                { pageSlug = "guides"
                                , publishedSnapshotMarkdown = "Guide body."
                                , reason = Just "Outdated."
                                }
                            )
            ]
        , Test.describe "publishedMarkdownForSlug"
            [ Test.test "empty when page missing" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "demo" "Demo" Dict.empty
                    in
                    SubmissionReviewDetail.publishedMarkdownForSlug wiki "nope"
                        |> Expect.equal ""
            , Test.test "empty when page has no published revision" <|
                \() ->
                    let
                        wiki : Wiki.Wiki
                        wiki =
                            Wiki.wikiWithPages "demo"
                                "Demo"
                                (Dict.singleton "only-pending"
                                    (Page.pendingOnly "only-pending" "draft")
                                )
                    in
                    SubmissionReviewDetail.publishedMarkdownForSlug wiki "only-pending"
                        |> Expect.equal ""
            ]
        ]
