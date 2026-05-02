module Evergreen.V26.WikiTodos exposing (..)

import Evergreen.V26.Page


type alias TableRow =
    { itemText : String
    , usedInPageSlugs : List Evergreen.V26.Page.Slug
    , maybeTodoText : Maybe String
    , maybeMissingPageSlug : Maybe Evergreen.V26.Page.Slug
    }
