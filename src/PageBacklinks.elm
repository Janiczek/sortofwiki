module PageBacklinks exposing (slugsPointingTo)

import Dict exposing (Dict)
import Page
import PageLinkRefs
import Set


{-| Other published pages in the wiki whose content links to `targetSlug` (excluding `targetSlug` itself).
First argument is the wiki path segment (same as `Wiki.Slug`). Sorted uniquely by `Page.Slug` order.
-}
slugsPointingTo : String -> Page.Slug -> Dict Page.Slug Page.Page -> List Page.Slug
slugsPointingTo wikiSlug targetSlug pages =
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

                else
                    let
                        linked : List Page.Slug
                        linked =
                            PageLinkRefs.linkedPageSlugs wikiSlug (Page.publishedMarkdownForLinks page)
                    in
                    if List.any (\slug -> String.toLower slug == normalizedTarget) linked then
                        Just sourceSlug

                    else
                        Nothing
            )
        |> Set.fromList
        |> Set.toList
