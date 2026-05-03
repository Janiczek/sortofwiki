module Evergreen.V28.WikiAuditLog exposing (..)

import Evergreen.V28.Wiki
import Time


type Error
    = WikiNotFound
    | WikiInactive
    | Forbidden


type AuditEventKindSummary
    = ApprovedSubmissionSummary
        { submissionId : String
        , pageSlug : String
        }
    | ApprovedPublishedNewPageSummary
        { submissionId : String
        , pageSlug : String
        }
    | ApprovedPublishedPageEditSummary
        { submissionId : String
        , pageSlug : String
        }
    | ApprovedPublishedPageDeleteSummary
        { submissionId : String
        , pageSlug : String
        }
    | RejectedSubmissionSummary
        { submissionId : String
        , pageSlug : String
        }
    | RequestedSubmissionChangesSummary
        { submissionId : String
        , pageSlug : String
        }
    | PromotedContributorToTrustedSummary
        { targetUsername : String
        }
    | DemotedTrustedToContributorSummary
        { targetUsername : String
        }
    | GrantedWikiAdminSummary
        { targetUsername : String
        }
    | RevokedWikiAdminSummary
        { targetUsername : String
        }
    | TrustedPublishedNewPageSummary
        { pageSlug : String
        , markdownCharCount : Int
        }
    | TrustedPublishedPageEditSummary
        { pageSlug : String
        , beforeCharCount : Int
        , afterCharCount : Int
        }
    | TrustedPublishedPageDeleteSummary
        { pageSlug : String
        , reason : String
        }


type alias AuditEventSummary =
    { at : Time.Posix
    , actorUsername : String
    , kind : AuditEventKindSummary
    }


type AuditEventKindFilterTag
    = ApprovedSubmissionKind
    | ApprovedPublishedNewPageKind
    | ApprovedPublishedPageEditKind
    | ApprovedPublishedPageDeleteKind
    | RejectedSubmissionKind
    | RequestedSubmissionChangesKind
    | PromotedContributorToTrustedKind
    | DemotedTrustedToContributorKind
    | GrantedWikiAdminKind
    | RevokedWikiAdminKind
    | TrustedPublishedNewPageKind
    | TrustedPublishedPageEditKind
    | TrustedPublishedPageDeleteKind


type alias AuditLogFilter =
    { actorUsernameSubstring : String
    , pageSlugSubstring : String
    , eventKindTags : List AuditEventKindFilterTag
    }


type alias HostAuditLogFilter =
    { wikiSlugSubstring : String
    , actorUsernameSubstring : String
    , pageSlugSubstring : String
    , eventKindTags : List AuditEventKindFilterTag
    }


type alias ScopedAuditEventSummary =
    { wikiSlug : Evergreen.V28.Wiki.Slug
    , at : Time.Posix
    , actorUsername : String
    , kind : AuditEventKindSummary
    }


type alias AuditDiffCacheKey =
    String


type EventDiffError
    = DiffWikiNotFound
    | DiffWikiInactive
    | DiffRowNotFound
    | DiffRowNotDiffable


type TrustedPublishAuditDiff
    = TrustedPublishNewPageDiff
        { pageSlug : String
        , markdown : String
        }
    | TrustedPublishPageEditDiff
        { pageSlug : String
        , beforeMarkdown : String
        , afterMarkdown : String
        }


type AuditEventKind
    = ApprovedSubmission
        { submissionId : String
        , pageSlug : String
        }
    | ApprovedPublishedNewPage
        { submissionId : String
        , pageSlug : String
        }
    | ApprovedPublishedPageEdit
        { submissionId : String
        , pageSlug : String
        }
    | ApprovedPublishedPageDelete
        { submissionId : String
        , pageSlug : String
        }
    | RejectedSubmission
        { submissionId : String
        , pageSlug : String
        }
    | RequestedSubmissionChanges
        { submissionId : String
        , pageSlug : String
        }
    | PromotedContributorToTrusted
        { targetUsername : String
        }
    | DemotedTrustedToContributor
        { targetUsername : String
        }
    | GrantedWikiAdmin
        { targetUsername : String
        }
    | RevokedWikiAdmin
        { targetUsername : String
        }
    | TrustedPublishedNewPage
        { pageSlug : String
        , markdown : String
        }
    | TrustedPublishedPageEdit
        { pageSlug : String
        , beforeMarkdown : String
        , afterMarkdown : String
        }
    | TrustedPublishedPageDelete
        { pageSlug : String
        , reason : String
        }


type alias AuditEvent =
    { at : Time.Posix
    , actorUsername : String
    , kind : AuditEventKind
    }
