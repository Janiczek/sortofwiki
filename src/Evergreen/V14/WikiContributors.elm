module Evergreen.V14.WikiContributors exposing (..)

import Dict
import Evergreen.V14.ContributorAccount
import Evergreen.V14.Wiki
import Evergreen.V14.WikiRole


type alias StoredContributor =
    { id : Evergreen.V14.ContributorAccount.Id
    , passwordVerifier : Evergreen.V14.ContributorAccount.Verifier
    , role : Evergreen.V14.WikiRole.WikiRole
    }


type alias Registry =
    Dict.Dict Evergreen.V14.Wiki.Slug (Dict.Dict String StoredContributor)
