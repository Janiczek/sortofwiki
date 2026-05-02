module Evergreen.V26.WikiContributors exposing (..)

import Dict
import Evergreen.V26.ContributorAccount
import Evergreen.V26.Wiki
import Evergreen.V26.WikiRole


type alias StoredContributor =
    { id : Evergreen.V26.ContributorAccount.Id
    , passwordVerifier : Evergreen.V26.ContributorAccount.Verifier
    , role : Evergreen.V26.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V26.Wiki.Slug (Dict.Dict String StoredContributor)
