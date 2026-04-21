module Evergreen.V2.ContributorWikiSession exposing (..)

import Evergreen.V2.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V2.WikiRole.WikiRole
    , displayUsername : String
    }
