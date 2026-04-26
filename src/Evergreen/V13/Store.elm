module Evergreen.V13.Store exposing (..)

import Dict
import Evergreen.V13.Page
import Evergreen.V13.Submission
import Evergreen.V13.SubmissionReviewDetail
import Evergreen.V13.Wiki
import Evergreen.V13.WikiAdminUsers
import Evergreen.V13.WikiAuditLog
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V13.Wiki.Slug Evergreen.V13.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V13.Wiki.Slug (RemoteData.RemoteData () Evergreen.V13.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V13.Wiki.Slug, Evergreen.V13.Page.Slug ) (RemoteData.RemoteData () Evergreen.V13.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V13.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V13.Submission.ReviewQueueError (List Evergreen.V13.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V13.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V13.Submission.MyPendingSubmissionsError (List Evergreen.V13.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V13.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V13.Submission.DetailsError Evergreen.V13.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V13.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V13.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V13.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V13.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V13.WikiAdminUsers.Error (List Evergreen.V13.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V13.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V13.WikiAuditLog.Error (List Evergreen.V13.WikiAuditLog.AuditEvent))))
    }
