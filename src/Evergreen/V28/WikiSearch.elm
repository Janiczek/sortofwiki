module Evergreen.V28.WikiSearch exposing (..)

import Dict
import Evergreen.V28.Page


type alias ResultItem =
    { pageSlug : Evergreen.V28.Page.Slug
    , score : Float
    }


type alias PrefixIndex =
    Dict.Dict String (Dict.Dict Evergreen.V28.Page.Slug Float)
