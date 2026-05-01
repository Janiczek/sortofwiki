module Evergreen.V16.WikiSearch exposing (..)

import Dict
import Evergreen.V16.Page


type alias ResultItem =
    { pageSlug : Evergreen.V16.Page.Slug
    , score : Float
    }


type alias PrefixIndex =
    Dict.Dict String (Dict.Dict Evergreen.V16.Page.Slug Float)
