module Evergreen.V4.ContributorWikiSession exposing (..)

import Evergreen.V4.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V4.WikiRole.WikiRole
    , displayUsername : String
    }
