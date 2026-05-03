module Evergreen.V29.WikiSearch exposing (..)

import Dict
import Evergreen.V29.Page


type alias ResultItem =
    { pageSlug : Evergreen.V29.Page.Slug
    , score : Float
    }


type alias PrefixIndex =
    Dict.Dict String (Dict.Dict Evergreen.V29.Page.Slug Float)
