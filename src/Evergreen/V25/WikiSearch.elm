module Evergreen.V25.WikiSearch exposing (..)

import Dict
import Evergreen.V25.Page


type alias ResultItem =
    { pageSlug : Evergreen.V25.Page.Slug
    , score : Float
    }


type alias PrefixIndex =
    Dict.Dict String (Dict.Dict Evergreen.V25.Page.Slug Float)
