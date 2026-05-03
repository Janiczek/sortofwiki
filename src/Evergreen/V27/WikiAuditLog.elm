module Evergreen.V27.WikiAuditLog exposing (..)

import Evergreen.V27.Wiki
import Time


type Error
    = WikiNotFound
    | WikiInactive
    | Forbidden


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


type alias ScopedAuditEvent =
    { wikiSlug : Evergreen.V27.Wiki.Slug
    , at : Time.Posix
    , actorUsername : String
    , kind : AuditEventKind
    }
