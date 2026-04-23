module Evergreen.V11.WikiContributors exposing (..)

import Dict
import Evergreen.V11.ContributorAccount
import Evergreen.V11.Wiki
import Evergreen.V11.WikiRole


type alias StoredContributor =
    { id : Evergreen.V11.ContributorAccount.Id
    , passwordVerifier : Evergreen.V11.ContributorAccount.Verifier
    , role : Evergreen.V11.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V11.Wiki.Slug (Dict.Dict String StoredContributor)
