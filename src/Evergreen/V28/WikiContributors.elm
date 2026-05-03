module Evergreen.V28.WikiContributors exposing (..)

import Dict
import Evergreen.V28.ContributorAccount
import Evergreen.V28.Wiki
import Evergreen.V28.WikiRole


type alias StoredContributor =
    { id : Evergreen.V28.ContributorAccount.Id
    , passwordVerifier : Evergreen.V28.ContributorAccount.Verifier
    , role : Evergreen.V28.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V28.Wiki.Slug (Dict.Dict String StoredContributor)
