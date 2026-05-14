module Evergreen.V32.ContributorWikiSession exposing (..)

import Evergreen.V32.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V32.WikiRole.WikiRole
    , displayUsername : String
    }
