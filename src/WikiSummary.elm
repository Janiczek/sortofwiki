module WikiSummary exposing (WikiSummary, catalogUrlPath)

{-| A hosted wiki entry shown on the public catalog.
-}


type alias WikiSummary =
    { slug : String
    , name : String
    }


{-| Path segment after origin for the wiki homepage, e.g. `/w/my-wiki`.
-}
catalogUrlPath : WikiSummary -> String
catalogUrlPath wiki =
    "/w/" ++ wiki.slug
