module Evergreen.V2.SubmissionReviewDetail exposing (..)

import Evergreen.V2.Page


type ReviewSubmissionDetailError
    = ReviewSubmissionDetailNotLoggedIn
    | ReviewSubmissionDetailWrongWikiSession
    | ReviewSubmissionDetailForbidden
    | ReviewSubmissionDetailWikiInactive
    | ReviewSubmissionDetailNotFound


type SubmissionReviewDetail
    = NewPageDiff
        { pageSlug : Evergreen.V2.Page.Slug
        , proposedMarkdown : String
        }
    | EditPageDiff
        { pageSlug : Evergreen.V2.Page.Slug
        , beforeMarkdown : String
        , afterMarkdown : String
        }
    | DeletePageDiff
        { pageSlug : Evergreen.V2.Page.Slug
        , publishedSnapshotMarkdown : String
        , reason : Maybe String
        }
