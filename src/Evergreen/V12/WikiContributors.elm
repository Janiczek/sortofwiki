module Evergreen.V12.WikiContributors exposing (..)

import Dict
import Evergreen.V12.ContributorAccount
import Evergreen.V12.Wiki
import Evergreen.V12.WikiRole


type alias StoredContributor =
    { id : Evergreen.V12.ContributorAccount.Id
    , passwordVerifier : Evergreen.V12.ContributorAccount.Verifier
    , role : Evergreen.V12.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V12.Wiki.Slug (Dict.Dict String StoredContributor)
