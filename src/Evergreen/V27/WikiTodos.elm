module Evergreen.V27.WikiTodos exposing (..)

import Evergreen.V27.Page


type alias TableRow =
    { itemText : String
    , usedInPageSlugs : List Evergreen.V27.Page.Slug
    , maybeTodoText : Maybe String
    , maybeMissingPageSlug : Maybe Evergreen.V27.Page.Slug
    }
