module Evergreen.V11.Store exposing (..)

import Dict
import Evergreen.V11.Page
import Evergreen.V11.Submission
import Evergreen.V11.SubmissionReviewDetail
import Evergreen.V11.Wiki
import Evergreen.V11.WikiAdminUsers
import Evergreen.V11.WikiAuditLog
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V11.Wiki.Slug Evergreen.V11.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V11.Wiki.Slug (RemoteData.RemoteData () Evergreen.V11.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V11.Wiki.Slug, Evergreen.V11.Page.Slug ) (RemoteData.RemoteData () Evergreen.V11.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V11.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V11.Submission.ReviewQueueError (List Evergreen.V11.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V11.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V11.Submission.MyPendingSubmissionsError (List Evergreen.V11.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V11.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V11.Submission.DetailsError Evergreen.V11.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V11.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V11.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V11.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V11.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V11.WikiAdminUsers.Error (List Evergreen.V11.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V11.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V11.WikiAuditLog.Error (List Evergreen.V11.WikiAuditLog.AuditEvent))))
    }
