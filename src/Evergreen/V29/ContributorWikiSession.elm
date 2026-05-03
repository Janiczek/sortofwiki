module Evergreen.V29.ContributorWikiSession exposing (..)

import Evergreen.V29.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V29.WikiRole.WikiRole
    , displayUsername : String
    }
