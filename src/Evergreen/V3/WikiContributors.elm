module Evergreen.V3.WikiContributors exposing (..)

import Dict
import Evergreen.V3.ContributorAccount
import Evergreen.V3.Wiki
import Evergreen.V3.WikiRole


type alias StoredContributor =
    { id : Evergreen.V3.ContributorAccount.Id
    , passwordVerifier : Evergreen.V3.ContributorAccount.Verifier
    , role : Evergreen.V3.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V3.Wiki.Slug (Dict.Dict String StoredContributor)
