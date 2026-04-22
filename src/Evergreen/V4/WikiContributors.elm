module Evergreen.V4.WikiContributors exposing (..)

import Dict
import Evergreen.V4.ContributorAccount
import Evergreen.V4.Wiki
import Evergreen.V4.WikiRole


type alias StoredContributor =
    { id : Evergreen.V4.ContributorAccount.Id
    , passwordVerifier : Evergreen.V4.ContributorAccount.Verifier
    , role : Evergreen.V4.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V4.Wiki.Slug (Dict.Dict String StoredContributor)
