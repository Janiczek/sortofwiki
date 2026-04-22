module Evergreen.V5.ContributorWikiSession exposing (..)

import Evergreen.V5.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V5.WikiRole.WikiRole
    , displayUsername : String
    }
