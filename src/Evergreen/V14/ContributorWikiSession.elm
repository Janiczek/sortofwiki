module Evergreen.V14.ContributorWikiSession exposing (..)

import Evergreen.V14.WikiRole


type alias ContributorWikiSession =
    { role : Evergreen.V14.WikiRole.WikiRole
    , displayUsername : String
    }
