module Evergreen.V26.WikiSearch exposing (..)

import Dict
import Evergreen.V26.Page


type alias ResultItem =
    { pageSlug : Evergreen.V26.Page.Slug
    , score : Float
    }


type alias PrefixIndex =
    Dict.Dict String (Dict.Dict Evergreen.V26.Page.Slug Float)
