module Evergreen.V3.ContributorWikiSession exposing (..)

import Evergreen.V3.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V3.WikiRole.WikiRole
    , displayUsername : String
    }
