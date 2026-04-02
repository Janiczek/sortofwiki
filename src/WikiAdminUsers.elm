module WikiAdminUsers exposing (DemoteTrustedError(..), Error(..), GrantTrustedToAdminError(..), ListedUser, PromoteContributorError(..), RevokeAdminError(..), demoteErrorToUserText, errorToUserText, grantTrustedToAdminErrorToUserText, promoteErrorToUserText, revokeAdminErrorToUserText)

import WikiRole


type Error
    = NotLoggedIn
    | WrongWikiSession
    | Forbidden
    | WikiNotFound


{-| Promote-to-trusted failures (story 21).
-}
type PromoteContributorError
    = PromoteNotLoggedIn
    | PromoteWrongWikiSession
    | PromoteForbidden
    | PromoteWikiNotFound
    | PromoteTargetNotFound
    | PromoteTargetNotContributor


{-| Demote-to-contributor failures (story 22).
-}
type DemoteTrustedError
    = DemoteNotLoggedIn
    | DemoteWrongWikiSession
    | DemoteForbidden
    | DemoteWikiNotFound
    | DemoteTargetNotFound
    | DemoteTargetNotTrusted


{-| Grant-admin failures (story 23); `ToBackend` uses `GrantWikiAdmin`.
-}
type GrantTrustedToAdminError
    = GrantTrustedNotLoggedIn
    | GrantTrustedWrongWikiSession
    | GrantTrustedForbidden
    | GrantTrustedWikiNotFound
    | GrantTrustedTargetNotFound
    | GrantTrustedTargetNotTrusted


{-| Revoke wiki admin failures (story 24); `ToBackend` uses `RevokeWikiAdmin`.
-}
type RevokeAdminError
    = RevokeAdminNotLoggedIn
    | RevokeAdminWrongWikiSession
    | RevokeAdminForbidden
    | RevokeAdminWikiNotFound
    | RevokeAdminTargetNotFound
    | RevokeAdminTargetNotAdmin
    | RevokeAdminCannotRevokeSelf


type alias ListedUser =
    { username : String
    , role : WikiRole.WikiRole
    }


errorToUserText : Error -> String
errorToUserText err =
    case err of
        NotLoggedIn ->
            "You must be logged in to view wiki users."

        WrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        Forbidden ->
            "Only wiki admins can open this page."

        WikiNotFound ->
            "This wiki was not found."


promoteErrorToUserText : PromoteContributorError -> String
promoteErrorToUserText err =
    case err of
        PromoteNotLoggedIn ->
            "You must be logged in to promote users."

        PromoteWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        PromoteForbidden ->
            "Only wiki admins can promote contributors."

        PromoteWikiNotFound ->
            "This wiki was not found."

        PromoteTargetNotFound ->
            "That user is not registered on this wiki."

        PromoteTargetNotContributor ->
            "Only standard contributors can be promoted to trusted."


demoteErrorToUserText : DemoteTrustedError -> String
demoteErrorToUserText err =
    case err of
        DemoteNotLoggedIn ->
            "You must be logged in to demote users."

        DemoteWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        DemoteForbidden ->
            "Only wiki admins can demote trusted contributors."

        DemoteWikiNotFound ->
            "This wiki was not found."

        DemoteTargetNotFound ->
            "That user is not registered on this wiki."

        DemoteTargetNotTrusted ->
            "Only trusted contributors can be demoted to standard contributor."


grantTrustedToAdminErrorToUserText : GrantTrustedToAdminError -> String
grantTrustedToAdminErrorToUserText err =
    case err of
        GrantTrustedNotLoggedIn ->
            "You must be logged in to grant admin rights."

        GrantTrustedWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        GrantTrustedForbidden ->
            "Only wiki admins can grant admin rights."

        GrantTrustedWikiNotFound ->
            "This wiki was not found."

        GrantTrustedTargetNotFound ->
            "That user is not registered on this wiki."

        GrantTrustedTargetNotTrusted ->
            "Only trusted contributors can be granted wiki admin."


revokeAdminErrorToUserText : RevokeAdminError -> String
revokeAdminErrorToUserText err =
    case err of
        RevokeAdminNotLoggedIn ->
            "You must be logged in to revoke admin rights."

        RevokeAdminWrongWikiSession ->
            "Your session is for a different wiki. Log in again on this wiki."

        RevokeAdminForbidden ->
            "Only wiki admins can revoke admin rights."

        RevokeAdminWikiNotFound ->
            "This wiki was not found."

        RevokeAdminTargetNotFound ->
            "That user is not registered on this wiki."

        RevokeAdminTargetNotAdmin ->
            "Only wiki admins can be demoted from admin."

        RevokeAdminCannotRevokeSelf ->
            "You cannot revoke your own wiki admin rights."
