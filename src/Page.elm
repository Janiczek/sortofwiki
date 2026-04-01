module Page exposing (Page, Slug)


type alias Page =
    { slug : Slug
    , content : String
    }


type alias Slug =
    String
