module Evergreen.V1.ContributorWikiSession exposing (..)

import Evergreen.V1.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V1.WikiRole.WikiRole
    , displayUsername : String
    }
