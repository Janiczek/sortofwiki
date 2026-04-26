module Evergreen.V13.SubmissionReviewDetail exposing (..)

import Evergreen.V13.Page


type ReviewSubmissionDetailError
    = ReviewSubmissionDetailNotLoggedIn
    | ReviewSubmissionDetailWrongWikiSession
    | ReviewSubmissionDetailForbidden
    | ReviewSubmissionDetailWikiInactive
    | ReviewSubmissionDetailNotFound


type SubmissionReviewDetail
    = NewPageDiff
        { pageSlug : Evergreen.V13.Page.Slug
        , proposedMarkdown : String
        }
    | EditPageDiff
        { pageSlug : Evergreen.V13.Page.Slug
        , beforeMarkdown : String
        , afterMarkdown : String
        }
    | DeletePageDiff
        { pageSlug : Evergreen.V13.Page.Slug
        , publishedSnapshotMarkdown : String
        , reason : Maybe String
        }
