module PageTags exposing (slugsPointingToTag)

import Dict exposing (Dict)
import Page
import Set


slugsPointingToTag : Page.Slug -> Dict Page.Slug Page.Page -> List Page.Slug
slugsPointingToTag targetSlug pages =
    let
        normalizedTarget : String
        normalizedTarget =
            String.toLower targetSlug
    in
    pages
        |> Dict.toList
        |> List.filterMap
            (\( sourceSlug, page ) ->
                if String.toLower sourceSlug == normalizedTarget then
                    Nothing

                else if List.any (\tag -> String.toLower tag == normalizedTarget) page.tags then
                    Just sourceSlug

                else
                    Nothing
            )
        |> Set.fromList
        |> Set.toList
