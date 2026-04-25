module Evergreen.V12.ContributorWikiSession exposing (..)

import Evergreen.V12.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V12.WikiRole.WikiRole
    , displayUsername : String
    }
