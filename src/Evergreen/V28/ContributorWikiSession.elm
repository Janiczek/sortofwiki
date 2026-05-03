module Evergreen.V28.ContributorWikiSession exposing (..)

import Evergreen.V28.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V28.WikiRole.WikiRole
    , displayUsername : String
    }
