module Evergreen.V17.WikiSearch exposing (..)

import Dict
import Evergreen.V17.Page


type alias ResultItem =
    { pageSlug : Evergreen.V17.Page.Slug
    , score : Float
    }


type alias PrefixIndex =
    Dict.Dict String (Dict.Dict Evergreen.V17.Page.Slug Float)
