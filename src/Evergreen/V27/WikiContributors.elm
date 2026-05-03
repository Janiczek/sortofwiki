module Evergreen.V27.WikiContributors exposing (..)

import Dict
import Evergreen.V27.ContributorAccount
import Evergreen.V27.Wiki
import Evergreen.V27.WikiRole


type alias StoredContributor =
    { id : Evergreen.V27.ContributorAccount.Id
    , passwordVerifier : Evergreen.V27.ContributorAccount.Verifier
    , role : Evergreen.V27.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V27.Wiki.Slug (Dict.Dict String StoredContributor)
