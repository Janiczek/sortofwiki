module Evergreen.V3.WikiAuditLog exposing (..)

import Evergreen.V3.Wiki
import Time


type Error
    = WikiNotFound
    | WikiInactive
    | NotLoggedIn
    | WrongWikiSession
    | Forbidden


type AuditEventKind
    = ApprovedSubmission
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
        }
    | TrustedPublishedPageEdit
        { pageSlug : String
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


type AuditEventKindFilterTag
    = ApprovedSubmissionKind
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


type alias ScopedAuditEvent =
    { wikiSlug : Evergreen.V3.Wiki.Slug
    , at : Time.Posix
    , actorUsername : String
    , kind : AuditEventKind
    }
