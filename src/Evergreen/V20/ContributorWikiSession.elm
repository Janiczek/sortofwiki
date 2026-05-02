module Evergreen.V20.ContributorWikiSession exposing (..)

import Evergreen.V20.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V20.WikiRole.WikiRole
    , displayUsername : String
    }
