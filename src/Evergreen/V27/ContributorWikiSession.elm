module Evergreen.V27.ContributorWikiSession exposing (..)

import Evergreen.V27.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V27.WikiRole.WikiRole
    , displayUsername : String
    }
