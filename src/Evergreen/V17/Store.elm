module Evergreen.V17.Store exposing (..)

import Dict
import Evergreen.V17.Page
import Evergreen.V17.Submission
import Evergreen.V17.SubmissionReviewDetail
import Evergreen.V17.Wiki
import Evergreen.V17.WikiAdminUsers
import Evergreen.V17.WikiAuditLog
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V17.Wiki.Slug Evergreen.V17.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V17.Wiki.Slug (RemoteData.RemoteData () Evergreen.V17.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V17.Wiki.Slug, Evergreen.V17.Page.Slug ) (RemoteData.RemoteData () Evergreen.V17.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V17.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V17.Submission.ReviewQueueError (List Evergreen.V17.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V17.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V17.Submission.MyPendingSubmissionsError (List Evergreen.V17.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V17.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V17.Submission.DetailsError Evergreen.V17.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V17.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V17.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V17.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V17.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V17.WikiAdminUsers.Error (List Evergreen.V17.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V17.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V17.WikiAuditLog.Error (List Evergreen.V17.WikiAuditLog.AuditEvent))))
    }
