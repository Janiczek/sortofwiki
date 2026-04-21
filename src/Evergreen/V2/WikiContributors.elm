module Evergreen.V2.WikiContributors exposing (..)

import Dict
import Evergreen.V2.ContributorAccount
import Evergreen.V2.Wiki
import Evergreen.V2.WikiRole


type alias StoredContributor =
    { id : Evergreen.V2.ContributorAccount.Id
    , passwordVerifier : Evergreen.V2.ContributorAccount.Verifier
    , role : Evergreen.V2.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V2.Wiki.Slug (Dict.Dict String StoredContributor)
