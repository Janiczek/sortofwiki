module Evergreen.V27.WikiSearch exposing (..)

import Dict
import Evergreen.V27.Page


type alias ResultItem =
    { pageSlug : Evergreen.V27.Page.Slug
    , score : Float
    }


type alias PrefixIndex =
    Dict.Dict String (Dict.Dict Evergreen.V27.Page.Slug Float)
