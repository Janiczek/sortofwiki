module Evergreen.V2.WikiAdminUsers exposing (..)

import Evergreen.V2.WikiRole


type Error
    = NotLoggedIn
    | WrongWikiSession
    | Forbidden
    | WikiNotFound
    | WikiInactive


type alias ListedUser =
    { username : String
    , role : Evergreen.V2.WikiRole.WikiRole
    }


type PromoteContributorError
    = PromoteNotLoggedIn
    | PromoteWrongWikiSession
    | PromoteForbidden
    | PromoteWikiNotFound
    | PromoteWikiInactive
    | PromoteTargetNotFound
    | PromoteTargetNotContributor


type DemoteTrustedError
    = DemoteNotLoggedIn
    | DemoteWrongWikiSession
    | DemoteForbidden
    | DemoteWikiNotFound
    | DemoteWikiInactive
    | DemoteTargetNotFound
    | DemoteTargetNotTrusted


type GrantTrustedToAdminError
    = GrantTrustedNotLoggedIn
    | GrantTrustedWrongWikiSession
    | GrantTrustedForbidden
    | GrantTrustedWikiNotFound
    | GrantTrustedWikiInactive
    | GrantTrustedTargetNotFound
    | GrantTrustedTargetNotTrusted


type RevokeAdminError
    = RevokeAdminNotLoggedIn
    | RevokeAdminWrongWikiSession
    | RevokeAdminForbidden
    | RevokeAdminWikiNotFound
    | RevokeAdminWikiInactive
    | RevokeAdminTargetNotFound
    | RevokeAdminTargetNotAdmin
    | RevokeAdminCannotRevokeSelf
