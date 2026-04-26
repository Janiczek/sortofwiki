module Evergreen.V13.WikiContributors exposing (..)

import Dict
import Evergreen.V13.ContributorAccount
import Evergreen.V13.Wiki
import Evergreen.V13.WikiRole


type alias StoredContributor =
    { id : Evergreen.V13.ContributorAccount.Id
    , passwordVerifier : Evergreen.V13.ContributorAccount.Verifier
    , role : Evergreen.V13.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V13.Wiki.Slug (Dict.Dict String StoredContributor)
