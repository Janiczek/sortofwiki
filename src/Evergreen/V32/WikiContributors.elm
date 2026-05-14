module Evergreen.V32.WikiContributors exposing (..)

import Dict
import Evergreen.V32.ContributorAccount
import Evergreen.V32.Wiki
import Evergreen.V32.WikiRole


type alias StoredContributor =
    { id : Evergreen.V32.ContributorAccount.Id
    , passwordVerifier : Evergreen.V32.ContributorAccount.Verifier
    , role : Evergreen.V32.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V32.Wiki.Slug (Dict.Dict String StoredContributor)
