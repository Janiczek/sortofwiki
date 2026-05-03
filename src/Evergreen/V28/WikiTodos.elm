module Evergreen.V28.WikiTodos exposing (..)

import Evergreen.V28.Page


type alias TableRow =
    { itemText : String
    , usedInPageSlugs : List Evergreen.V28.Page.Slug
    , maybeTodoText : Maybe String
    , maybeMissingPageSlug : Maybe Evergreen.V28.Page.Slug
    }
