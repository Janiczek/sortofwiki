module Evergreen.V25.ContributorWikiSession exposing (..)

import Evergreen.V25.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V25.WikiRole.WikiRole
    , displayUsername : String
    }
