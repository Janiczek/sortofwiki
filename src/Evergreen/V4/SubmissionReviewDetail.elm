module Evergreen.V4.SubmissionReviewDetail exposing (..)

import Evergreen.V4.Page


type ReviewSubmissionDetailError
    = ReviewSubmissionDetailNotLoggedIn
    | ReviewSubmissionDetailWrongWikiSession
    | ReviewSubmissionDetailForbidden
    | ReviewSubmissionDetailWikiInactive
    | ReviewSubmissionDetailNotFound


type SubmissionReviewDetail
    = NewPageDiff
        { pageSlug : Evergreen.V4.Page.Slug
        , proposedMarkdown : String
        }
    | EditPageDiff
        { pageSlug : Evergreen.V4.Page.Slug
        , beforeMarkdown : String
        , afterMarkdown : String
        }
    | DeletePageDiff
        { pageSlug : Evergreen.V4.Page.Slug
        , publishedSnapshotMarkdown : String
        , reason : Maybe String
        }
