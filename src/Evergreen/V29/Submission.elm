module Evergreen.V29.Submission exposing (..)

import Evergreen.V29.ContributorAccount
import Evergreen.V29.Page
import Evergreen.V29.Wiki


type ReviewQueueError
    = ReviewQueueNotLoggedIn
    | ReviewQueueWrongWikiSession
    | ReviewQueueForbidden
    | ReviewQueueWikiInactive


type Id
    = Id String


type alias ReviewQueueItem =
    { id : Id
    , kindLabel : String
    , authorDisplay : String
    , maybePageSlug : Maybe Evergreen.V29.Page.Slug
    }


type MyPendingSubmissionsError
    = MyPendingSubmissionsNotLoggedIn
    | MyPendingSubmissionsWrongWikiSession
    | MyPendingSubmissionsWikiInactive
    | MyPendingSubmissionsForbiddenTrustedModerator


type Status
    = Draft
    | Pending
    | Approved
    | Rejected
    | NeedsRevision


type alias MyPendingSubmissionListItem =
    { id : Id
    , status : Status
    , statusLabel : String
    , kindLabel : String
    , maybePageSlug : Maybe Evergreen.V29.Page.Slug
    }


type DetailsError
    = DetailsNotLoggedIn
    | DetailsWrongWikiSession
    | DetailsWikiInactive
    | DetailsNotFound
    | DetailsForbidden


type ContributorSubmissionKind
    = ContributorKindNewPage
    | ContributorKindEditPage
    | ContributorKindDeletePage


type alias EditConflictContext =
    { pageSlug : Evergreen.V29.Page.Slug
    , baseMarkdown : String
    , baseRevision : Int
    , proposedMarkdown : String
    , currentMarkdown : String
    , currentRevision : Int
    }


type alias ContributorView =
    { id : Id
    , status : Status
    , kindSummary : String
    , contributionKind : ContributorSubmissionKind
    , reviewerNote : Maybe String
    , conflictContext : Maybe EditConflictContext
    , compareOriginalMarkdown : String
    , compareNewMarkdown : String
    , maybeNewPageSlug : Maybe Evergreen.V29.Page.Slug
    , maybeEditPageSlug : Maybe Evergreen.V29.Page.Slug
    }


type ValidationError
    = SlugEmpty
    | SlugTooLong
    | SlugInvalidChars
    | BodyEmpty


type SubmitNewPageError
    = NotLoggedIn
    | WrongWikiSession
    | WikiNotFound
    | WikiInactive
    | Validation ValidationError
    | SlugAlreadyInUse


type NewPageSubmitSuccess
    = NewPagePublishedImmediately
    | NewPageSubmittedForReview Id


type SaveNewPageDraftError
    = SaveNewPageDraftNotLoggedIn
    | SaveNewPageDraftWrongWikiSession
    | SaveNewPageDraftValidation ValidationError
    | SaveNewPageDraftSlugReserved
    | SaveNewPageDraftNotFound
    | SaveNewPageDraftForbidden
    | SaveNewPageDraftWikiNotFound
    | SaveNewPageDraftWikiInactive


type SubmitPageEditError
    = EditNotLoggedIn
    | EditWrongWikiSession
    | EditWikiNotFound
    | EditWikiInactive
    | EditValidation ValidationError
    | EditTargetPageNotPublished
    | EditAlreadyPendingForAuthor


type EditSubmitSuccess
    = EditPublishedImmediately
    | EditSubmittedForReview Id


type SavePageEditDraftError
    = SavePageEditDraftNotLoggedIn
    | SavePageEditDraftWrongWikiSession
    | SavePageEditDraftValidation ValidationError
    | SavePageEditDraftTargetNotPublished
    | SavePageEditDraftAlreadyPendingEdit
    | SavePageEditDraftNotFound
    | SavePageEditDraftForbidden
    | SavePageEditDraftWikiNotFound
    | SavePageEditDraftWikiInactive


type DeleteReasonError
    = ReasonRequired
    | ReasonTooLong


type PageDeletionPreconditionError
    = PageDeletionNotLoggedIn
    | PageDeletionWrongWikiSession
    | PageDeletionWikiNotFound
    | PageDeletionWikiInactive
    | PageDeletionValidation DeleteReasonError
    | PageDeletionTargetNotPublished


type SubmitDraftForReviewError
    = SubmitDraftForReviewNotLoggedIn
    | SubmitDraftForReviewWrongWikiSession
    | SubmitDraftForReviewWikiNotFound
    | SubmitDraftForReviewWikiInactive
    | SubmitDraftForReviewNotDraft
    | SubmitDraftForReviewValidation ValidationError
    | SubmitDraftForReviewSlugInUse
    | SubmitDraftForReviewPageExists
    | SubmitDraftForReviewEditTargetNotPublished
    | SubmitDraftForReviewEditAlreadyPending
    | SubmitDraftForReviewDeleteTargetNotPublished
    | SubmitDraftForReviewDeleteReasonInvalid DeleteReasonError
    | SubmitDraftForReviewNotFound
    | SubmitDraftForReviewForbidden
    | SubmitDraftForReviewDeleteForbiddenTrustedModerator


type RequestPublishedPageDeletionError
    = RequestPublishedPageDeletionPrecondition PageDeletionPreconditionError
    | RequestPublishedPageDeletionForbiddenTrustedModerator
    | RequestPublishedPageDeletionSubmitDraftStepFailed SubmitDraftForReviewError


type DeletePublishedPageImmediatelyError
    = DeletePublishedPageImmediatelyPrecondition PageDeletionPreconditionError
    | DeletePublishedPageImmediatelyForbiddenUntrustedContributor


type PageDeleteFormError
    = PageDeleteRequestFailed RequestPublishedPageDeletionError
    | PageDeleteImmediateFailed DeletePublishedPageImmediatelyError


type PageDeleteFormSuccess
    = DeletePublishedImmediately
    | DeleteSubmittedForReview Id


type SavePageDeleteDraftError
    = SavePageDeleteDraftNotLoggedIn
    | SavePageDeleteDraftWrongWikiSession
    | SavePageDeleteDraftReasonInvalid DeleteReasonError
    | SavePageDeleteDraftTargetNotPublished
    | SavePageDeleteDraftNotFound
    | SavePageDeleteDraftForbidden
    | SavePageDeleteDraftWikiNotFound
    | SavePageDeleteDraftWikiInactive
    | SavePageDeleteDraftForbiddenTrustedModerator


type ApproveSubmissionError
    = ApproveNotLoggedIn
    | ApproveWrongWikiSession
    | ApproveForbidden
    | ApproveWikiNotFound
    | ApproveWikiInactive
    | ApproveSubmissionNotFound
    | ApproveNotPending
    | ApproveNewPageSlugTaken
    | ApproveEditTargetNotPublished
    | ApproveDeleteTargetNotPublished


type RejectReasonError
    = RejectReasonEmpty
    | RejectReasonTooLong


type RejectSubmissionError
    = RejectNotLoggedIn
    | RejectWrongWikiSession
    | RejectForbidden
    | RejectWikiNotFound
    | RejectWikiInactive
    | RejectSubmissionNotFound
    | RejectNotPending
    | RejectReasonInvalid RejectReasonError


type RequestChangesSubmissionError
    = RequestChangesNotLoggedIn
    | RequestChangesWrongWikiSession
    | RequestChangesForbidden
    | RequestChangesWikiNotFound
    | RequestChangesWikiInactive
    | RequestChangesSubmissionNotFound
    | RequestChangesNotPending
    | RequestChangesGuidanceInvalid RejectReasonError


type alias NewPageBody =
    { pageSlug : Evergreen.V29.Page.Slug
    , markdown : String
    , tags : List Evergreen.V29.Page.Slug
    }


type alias EditPageBody =
    { pageSlug : Evergreen.V29.Page.Slug
    , baseMarkdown : String
    , baseRevision : Int
    , proposedMarkdown : String
    , tags : List Evergreen.V29.Page.Slug
    }


type alias DeletePageBody =
    { pageSlug : Evergreen.V29.Page.Slug
    , reason : Maybe String
    }


type Kind
    = NewPage NewPageBody
    | EditPage EditPageBody
    | DeletePage DeletePageBody


type alias Submission =
    { id : Id
    , wikiSlug : Evergreen.V29.Wiki.Slug
    , authorId : Evergreen.V29.ContributorAccount.Id
    , kind : Kind
    , status : Status
    , reviewerNote : Maybe String
    }


type WithdrawSubmissionError
    = WithdrawSubmissionNotLoggedIn
    | WithdrawSubmissionWrongWikiSession
    | WithdrawSubmissionWikiNotFound
    | WithdrawSubmissionWikiInactive
    | WithdrawSubmissionNotPendingOrNeedsRevision
    | WithdrawSubmissionNotFound
    | WithdrawSubmissionForbidden


type DeleteMySubmissionError
    = DeleteMySubmissionNotLoggedIn
    | DeleteMySubmissionWrongWikiSession
    | DeleteMySubmissionWikiNotFound
    | DeleteMySubmissionWikiInactive
    | DeleteMySubmissionApproved
    | DeleteMySubmissionNotFound
    | DeleteMySubmissionForbidden
