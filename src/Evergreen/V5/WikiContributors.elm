module Evergreen.V5.WikiContributors exposing (..)

import Dict
import Evergreen.V5.ContributorAccount
import Evergreen.V5.Wiki
import Evergreen.V5.WikiRole


type alias StoredContributor =
    { id : Evergreen.V5.ContributorAccount.Id
    , passwordVerifier : Evergreen.V5.ContributorAccount.Verifier
    , role : Evergreen.V5.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V5.Wiki.Slug (Dict.Dict String StoredContributor)
