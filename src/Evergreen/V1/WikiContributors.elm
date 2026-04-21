module Evergreen.V1.WikiContributors exposing (..)

import Dict
import Evergreen.V1.ContributorAccount
import Evergreen.V1.Wiki
import Evergreen.V1.WikiRole


type alias StoredContributor =
    { id : Evergreen.V1.ContributorAccount.Id
    , passwordVerifier : Evergreen.V1.ContributorAccount.Verifier
    , role : Evergreen.V1.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V1.Wiki.Slug (Dict.Dict String StoredContributor)
