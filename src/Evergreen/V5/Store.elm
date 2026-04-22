module Evergreen.V5.Store exposing (..)

import Dict
import Evergreen.V5.Page
import Evergreen.V5.Submission
import Evergreen.V5.SubmissionReviewDetail
import Evergreen.V5.Wiki
import Evergreen.V5.WikiAdminUsers
import Evergreen.V5.WikiAuditLog
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V5.Wiki.Slug Evergreen.V5.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V5.Wiki.Slug (RemoteData.RemoteData () Evergreen.V5.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V5.Wiki.Slug, Evergreen.V5.Page.Slug ) (RemoteData.RemoteData () Evergreen.V5.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V5.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V5.Submission.ReviewQueueError (List Evergreen.V5.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V5.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V5.Submission.MyPendingSubmissionsError (List Evergreen.V5.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V5.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V5.Submission.DetailsError Evergreen.V5.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V5.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V5.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V5.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V5.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V5.WikiAdminUsers.Error (List Evergreen.V5.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V5.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V5.WikiAuditLog.Error (List Evergreen.V5.WikiAuditLog.AuditEvent))))
    }
