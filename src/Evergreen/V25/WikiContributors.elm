module Evergreen.V25.WikiContributors exposing (..)

import Dict
import Evergreen.V25.ContributorAccount
import Evergreen.V25.Wiki
import Evergreen.V25.WikiRole


type alias StoredContributor =
    { id : Evergreen.V25.ContributorAccount.Id
    , passwordVerifier : Evergreen.V25.ContributorAccount.Verifier
    , role : Evergreen.V25.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V25.Wiki.Slug (Dict.Dict String StoredContributor)
