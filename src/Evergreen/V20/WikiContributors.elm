module Evergreen.V20.WikiContributors exposing (..)

import Dict
import Evergreen.V20.ContributorAccount
import Evergreen.V20.Wiki
import Evergreen.V20.WikiRole


type alias StoredContributor =
    { id : Evergreen.V20.ContributorAccount.Id
    , passwordVerifier : Evergreen.V20.ContributorAccount.Verifier
    , role : Evergreen.V20.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V20.Wiki.Slug (Dict.Dict String StoredContributor)
