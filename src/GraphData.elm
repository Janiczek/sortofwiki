module GraphData exposing (EdgeDirection(..), normalizeEdges, totalEdgeCountsByNormalizedSlug)

import Dict exposing (Dict)


type EdgeDirection
    = Directed
    | Undirected


normalizeEdges :
    { fromSlug : edge -> String
    , toSlug : edge -> String
    , direction : edge -> EdgeDirection
    , kindSortKey : edge -> String
    , toUndirected : { canonicalFrom : String, canonicalTo : String } -> edge -> edge
    }
    -> List edge
    -> List edge
normalizeEdges config rawEdges =
    let
        edgeSortKey : edge -> String
        edgeSortKey edge =
            config.kindSortKey edge
                ++ "|"
                ++ slugSortKey (config.fromSlug edge)
                ++ "|"
                ++ slugSortKey (config.toSlug edge)
                ++ "|"
                ++ directionSortKey (config.direction edge)

        directedEdgeKey : edge -> String
        directedEdgeKey edge =
            config.kindSortKey edge
                ++ "|"
                ++ slugSortKey (config.fromSlug edge)
                ++ "|"
                ++ slugSortKey (config.toSlug edge)

        reverseDirectedEdgeKey : edge -> String
        reverseDirectedEdgeKey edge =
            config.kindSortKey edge
                ++ "|"
                ++ slugSortKey (config.toSlug edge)
                ++ "|"
                ++ slugSortKey (config.fromSlug edge)

        undirectedEdgeKey : edge -> String
        undirectedEdgeKey edge =
            let
                ( canonicalFrom, canonicalTo ) =
                    canonicalPair (config.fromSlug edge) (config.toSlug edge)
            in
            config.kindSortKey edge
                ++ "|"
                ++ slugSortKey canonicalFrom
                ++ "|"
                ++ slugSortKey canonicalTo

        rawLookup : Dict String edge
        rawLookup =
            rawEdges
                |> List.sortBy edgeSortKey
                |> List.foldl
                    (\edge acc -> Dict.insert (directedEdgeKey edge) edge acc)
                    Dict.empty

        normalizedLookup : Dict String edge
        normalizedLookup =
            rawLookup
                |> Dict.values
                |> List.sortBy edgeSortKey
                |> List.foldl
                    (\edge acc ->
                        let
                            normalizedEdge : edge
                            normalizedEdge =
                                if config.fromSlug edge /= config.toSlug edge && Dict.member (reverseDirectedEdgeKey edge) rawLookup then
                                    let
                                        ( canonicalFrom, canonicalTo ) =
                                            canonicalPair (config.fromSlug edge) (config.toSlug edge)
                                    in
                                    config.toUndirected
                                        { canonicalFrom = canonicalFrom
                                        , canonicalTo = canonicalTo
                                        }
                                        edge

                                else
                                    edge

                            normalizedKey : String
                            normalizedKey =
                                case config.direction normalizedEdge of
                                    Directed ->
                                        directedEdgeKey normalizedEdge

                                    Undirected ->
                                        undirectedEdgeKey normalizedEdge
                        in
                        Dict.insert normalizedKey normalizedEdge acc
                    )
                    Dict.empty
    in
    normalizedLookup
        |> Dict.values
        |> List.sortBy edgeSortKey


totalEdgeCountsByNormalizedSlug :
    { fromSlug : edge -> String
    , toSlug : edge -> String
    }
    -> List edge
    -> Dict String Int
totalEdgeCountsByNormalizedSlug config edges =
    edges
        |> List.foldl
            (\edge acc ->
                let
                    normalizedFrom : String
                    normalizedFrom =
                        String.toLower (config.fromSlug edge)

                    normalizedTarget : String
                    normalizedTarget =
                        String.toLower (config.toSlug edge)

                    increment : String -> Dict String Int -> Dict String Int
                    increment normalizedSlug counts =
                        Dict.update normalizedSlug
                            (\maybeCount ->
                                case maybeCount of
                                    Just count ->
                                        Just (count + 1)

                                    Nothing ->
                                        Just 1
                            )
                            counts
                in
                if normalizedFrom == normalizedTarget then
                    increment normalizedFrom acc

                else
                    acc
                        |> increment normalizedFrom
                        |> increment normalizedTarget
            )
            Dict.empty


directionSortKey : EdgeDirection -> String
directionSortKey direction =
    case direction of
        Directed ->
            "0"

        Undirected ->
            "1"


canonicalPair : String -> String -> ( String, String )
canonicalPair left right =
    if slugSortKey left <= slugSortKey right then
        ( left, right )

    else
        ( right, left )


slugSortKey : String -> String
slugSortKey pageSlug =
    String.toLower pageSlug ++ "|" ++ pageSlug
