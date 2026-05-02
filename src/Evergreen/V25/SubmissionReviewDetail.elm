module Evergreen.V25.SubmissionReviewDetail exposing (..)

import Evergreen.V25.Page


type ReviewSubmissionDetailError
    = ReviewSubmissionDetailNotLoggedIn
    | ReviewSubmissionDetailWrongWikiSession
    | ReviewSubmissionDetailForbidden
    | ReviewSubmissionDetailWikiInactive
    | ReviewSubmissionDetailNotFound


type SubmissionReviewDetail
    = NewPageDiff
        { pageSlug : Evergreen.V25.Page.Slug
        , proposedMarkdown : String
        }
    | EditPageDiff
        { pageSlug : Evergreen.V25.Page.Slug
        , beforeMarkdown : String
        , afterMarkdown : String
        }
    | DeletePageDiff
        { pageSlug : Evergreen.V25.Page.Slug
        , publishedSnapshotMarkdown : String
        , reason : Maybe String
        }
