module Evergreen.V11.ContributorWikiSession exposing (..)

import Evergreen.V11.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V11.WikiRole.WikiRole
    , displayUsername : String
    }
