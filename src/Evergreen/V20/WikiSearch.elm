module Evergreen.V20.WikiSearch exposing (..)

import Dict
import Evergreen.V20.Page


type alias ResultItem =
    { pageSlug : Evergreen.V20.Page.Slug
    , score : Float
    }


type alias PrefixIndex =
    Dict.Dict String (Dict.Dict Evergreen.V20.Page.Slug Float)
