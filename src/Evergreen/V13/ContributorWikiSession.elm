module Evergreen.V13.ContributorWikiSession exposing (..)

import Evergreen.V13.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V13.WikiRole.WikiRole
    , displayUsername : String
    }
