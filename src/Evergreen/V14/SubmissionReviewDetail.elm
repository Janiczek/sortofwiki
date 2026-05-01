module Evergreen.V14.SubmissionReviewDetail exposing (..)

import Evergreen.V14.Page


type ReviewSubmissionDetailError
    = ReviewSubmissionDetailNotLoggedIn
    | ReviewSubmissionDetailWrongWikiSession
    | ReviewSubmissionDetailForbidden
    | ReviewSubmissionDetailWikiInactive
    | ReviewSubmissionDetailNotFound


type SubmissionReviewDetail
    = NewPageDiff
        { pageSlug : Evergreen.V14.Page.Slug
        , proposedMarkdown : String
        }
    | EditPageDiff
        { pageSlug : Evergreen.V14.Page.Slug
        , beforeMarkdown : String
        , afterMarkdown : String
        }
    | DeletePageDiff
        { pageSlug : Evergreen.V14.Page.Slug
        , publishedSnapshotMarkdown : String
        , reason : Maybe String
        }
