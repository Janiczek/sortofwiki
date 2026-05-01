module Evergreen.V17.ContributorWikiSession exposing (..)

import Evergreen.V17.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V17.WikiRole.WikiRole
    , displayUsername : String
    }
