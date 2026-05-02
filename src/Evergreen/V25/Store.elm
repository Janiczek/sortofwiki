module Evergreen.V25.Store exposing (..)

import Dict
import Evergreen.V25.Page
import Evergreen.V25.Submission
import Evergreen.V25.SubmissionReviewDetail
import Evergreen.V25.Wiki
import Evergreen.V25.WikiAdminUsers
import Evergreen.V25.WikiAuditLog
import Evergreen.V25.WikiTodos
import RemoteData


type alias Store =
    { wikiCatalog : RemoteData.RemoteData () (Dict.Dict Evergreen.V25.Wiki.Slug Evergreen.V25.Wiki.CatalogEntry)
    , wikiDetails : Dict.Dict Evergreen.V25.Wiki.Slug (RemoteData.RemoteData () Evergreen.V25.Wiki.FrontendDetails)
    , publishedPages : Dict.Dict ( Evergreen.V25.Wiki.Slug, Evergreen.V25.Page.Slug ) (RemoteData.RemoteData () Evergreen.V25.Page.FrontendDetails)
    , reviewQueues : Dict.Dict Evergreen.V25.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V25.Submission.ReviewQueueError (List Evergreen.V25.Submission.ReviewQueueItem)))
    , myPendingSubmissions : Dict.Dict Evergreen.V25.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V25.Submission.MyPendingSubmissionsError (List Evergreen.V25.Submission.MyPendingSubmissionListItem)))
    , submissionDetails : Dict.Dict ( Evergreen.V25.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V25.Submission.DetailsError Evergreen.V25.Submission.ContributorView))
    , reviewSubmissionDetails : Dict.Dict ( Evergreen.V25.Wiki.Slug, String ) (RemoteData.RemoteData () (Result Evergreen.V25.SubmissionReviewDetail.ReviewSubmissionDetailError Evergreen.V25.SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers : Dict.Dict Evergreen.V25.Wiki.Slug (RemoteData.RemoteData () (Result Evergreen.V25.WikiAdminUsers.Error (List Evergreen.V25.WikiAdminUsers.ListedUser)))
    , wikiAuditLogs : Dict.Dict Evergreen.V25.Wiki.Slug (Dict.Dict String (RemoteData.RemoteData () (Result Evergreen.V25.WikiAuditLog.Error (List Evergreen.V25.WikiAuditLog.AuditEvent))))
    , wikiTodos : Dict.Dict Evergreen.V25.Wiki.Slug (RemoteData.RemoteData () (Result () (List Evergreen.V25.WikiTodos.TableRow)))
    }
