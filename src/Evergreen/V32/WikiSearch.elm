module Evergreen.V32.WikiSearch exposing (..)

import Dict
import Evergreen.V32.Page


type alias ResultItem =
    { pageSlug : Evergreen.V32.Page.Slug
    , score : Float
    }


type alias PrefixIndex =
    Dict.Dict String (Dict.Dict Evergreen.V32.Page.Slug Float)
