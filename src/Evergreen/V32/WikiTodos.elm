module Evergreen.V32.WikiTodos exposing (..)

import Evergreen.V32.Page


type alias TableRow =
    { itemText : String
    , usedInPageSlugs : List Evergreen.V32.Page.Slug
    , maybeTodoText : Maybe String
    , maybeMissingPageSlug : Maybe Evergreen.V32.Page.Slug
    }
