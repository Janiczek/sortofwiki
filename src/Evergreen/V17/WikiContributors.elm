module Evergreen.V17.WikiContributors exposing (..)

import Dict
import Evergreen.V17.ContributorAccount
import Evergreen.V17.Wiki
import Evergreen.V17.WikiRole


type alias StoredContributor =
    { id : Evergreen.V17.ContributorAccount.Id
    , passwordVerifier : Evergreen.V17.ContributorAccount.Verifier
    , role : Evergreen.V17.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V17.Wiki.Slug (Dict.Dict String StoredContributor)
