module Evergreen.V3.Store exposing (..)

import Dict
import Evergreen.V3.Page
import Evergreen.V3.Submission
import Evergreen.V3.SubmissionReviewDetail
import Evergreen.V3.Wiki
import Evergreen.V3.WikiAdminUsers
import Evergreen.V3.WikiAuditLog
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V3.Wiki.Slug Evergreen.V3.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V3.Wiki.Slug (RemoteData.RemoteData () Evergreen.V3.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V3.Wiki.Slug, Evergreen.V3.Page.Slug ) (RemoteData.RemoteData () Evergreen.V3.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V3.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V3.Submission.ReviewQueueError (List Evergreen.V3.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V3.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V3.Submission.MyPendingSubmissionsError (List Evergreen.V3.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V3.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V3.Submission.DetailsError Evergreen.V3.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V3.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V3.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V3.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V3.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V3.WikiAdminUsers.Error (List Evergreen.V3.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V3.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V3.WikiAuditLog.Error (List Evergreen.V3.WikiAuditLog.AuditEvent))))
    }
