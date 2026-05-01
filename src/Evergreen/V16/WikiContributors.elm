module Evergreen.V16.WikiContributors exposing (..)

import Dict
import Evergreen.V16.ContributorAccount
import Evergreen.V16.Wiki
import Evergreen.V16.WikiRole


type alias StoredContributor =
    { id : Evergreen.V16.ContributorAccount.Id
    , passwordVerifier : Evergreen.V16.ContributorAccount.Verifier
    , role : Evergreen.V16.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V16.Wiki.Slug (Dict.Dict String StoredContributor)
