module SubmissionReviewDetail exposing
    ( ReviewSubmissionDetailError(..)
    , SubmissionReviewDetail(..)
    , publishedMarkdownForSlug
    , reviewDetailFromWikiAndSubmission
    , reviewSubmissionDetailErrorToUserText
    )

import Dict
import Page
import Submission
import Wiki


{-| Trusted-only: full submission payload for moderation diff (story 16).
-}
type SubmissionReviewDetail
    = NewPageDiff
        { pageSlug : Page.Slug
        , proposedMarkdown : String
        }
    | EditPageDiff
        { pageSlug : Page.Slug
        , beforeMarkdown : String
        , afterMarkdown : String
        }
    | DeletePageDiff
        { pageSlug : Page.Slug
        , publishedSnapshotMarkdown : String
        , reason : Maybe String
        }


{-| Authorization / lookup failures for `RequestReviewSubmissionDetail`.
-}
type ReviewSubmissionDetailError
    = ReviewSubmissionDetailNotLoggedIn
    | ReviewSubmissionDetailWrongWikiSession
    | ReviewSubmissionDetailForbidden
    | ReviewSubmissionDetailNotFound


reviewSubmissionDetailErrorToUserText : ReviewSubmissionDetailError -> String
reviewSubmissionDetailErrorToUserText err =
    case err of
        ReviewSubmissionDetailNotLoggedIn ->
            "Log in on this wiki to inspect this submission."

        ReviewSubmissionDetailWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        ReviewSubmissionDetailForbidden ->
            "You do not have permission to inspect this submission."

        ReviewSubmissionDetailNotFound ->
            "That submission was not found."


{-| Published markdown for a slug, or empty when the page is missing or has no published revision.
-}
publishedMarkdownForSlug : Wiki.Wiki -> Page.Slug -> String
publishedMarkdownForSlug wiki pageSlug =
    case Dict.get pageSlug wiki.pages of
        Nothing ->
            ""

        Just page ->
            Page.publishedMarkdownForLinks page


{-| Build the reviewer diff view from current wiki state and the stored submission.
-}
reviewDetailFromWikiAndSubmission : Wiki.Wiki -> Submission.Submission -> SubmissionReviewDetail
reviewDetailFromWikiAndSubmission wiki sub =
    case sub.kind of
        Submission.NewPage body ->
            NewPageDiff
                { pageSlug = body.pageSlug
                , proposedMarkdown = body.markdown
                }

        Submission.EditPage body ->
            EditPageDiff
                { pageSlug = body.pageSlug
                , beforeMarkdown = body.baseMarkdown
                , afterMarkdown = body.proposedMarkdown
                }

        Submission.DeletePage body ->
            DeletePageDiff
                { pageSlug = body.pageSlug
                , publishedSnapshotMarkdown = publishedMarkdownForSlug wiki body.pageSlug
                , reason = body.reason
                }
