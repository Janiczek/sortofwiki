module Evergreen.V26.ContributorWikiSession exposing (..)

import Evergreen.V26.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V26.WikiRole.WikiRole
    , displayUsername : String
    }
