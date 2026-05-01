module Evergreen.V16.ContributorWikiSession exposing (..)

import Evergreen.V16.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V16.WikiRole.WikiRole
    , displayUsername : String
    }
