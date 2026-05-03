module Evergreen.V29.WikiTodos exposing (..)

import Evergreen.V29.Page


type alias TableRow =
    { itemText : String
    , usedInPageSlugs : List Evergreen.V29.Page.Slug
    , maybeTodoText : Maybe String
    , maybeMissingPageSlug : Maybe Evergreen.V29.Page.Slug
    }
