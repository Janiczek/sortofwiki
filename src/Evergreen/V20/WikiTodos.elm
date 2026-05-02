module Evergreen.V20.WikiTodos exposing (..)

import Evergreen.V20.Page


type alias TableRow =
    { itemText : String
    , usedInPageSlugs : List Evergreen.V20.Page.Slug
    , maybeTodoText : Maybe String
    , maybeMissingPageSlug : Maybe Evergreen.V20.Page.Slug
    }
