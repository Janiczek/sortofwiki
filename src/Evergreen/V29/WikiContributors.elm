module Evergreen.V29.WikiContributors exposing (..)

import Dict
import Evergreen.V29.ContributorAccount
import Evergreen.V29.Wiki
import Evergreen.V29.WikiRole


type alias StoredContributor =
    { id : Evergreen.V29.ContributorAccount.Id
    , passwordVerifier : Evergreen.V29.ContributorAccount.Verifier
    , role : Evergreen.V29.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V29.Wiki.Slug (Dict.Dict String StoredContributor)
