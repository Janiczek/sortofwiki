module Evergreen.V25.WikiTodos exposing (..)

import Evergreen.V25.Page


type alias TableRow =
    { itemText : String
    , usedInPageSlugs : List Evergreen.V25.Page.Slug
    , maybeTodoText : Maybe String
    , maybeMissingPageSlug : Maybe Evergreen.V25.Page.Slug
    }
