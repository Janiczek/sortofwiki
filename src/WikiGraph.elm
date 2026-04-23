module WikiGraph exposing (Edge, EdgeDirection(..), EdgeKind(..), Summary, dot, summary)

import Dict exposing (Dict)
import Page
import PageLinkRefs
import Set
import Wiki


type alias Edge =
    { fromPageSlug : Page.Slug
    , toPageSlug : Page.Slug
    , direction : EdgeDirection
    , targetPublished : Bool
    , kind : EdgeKind
    }


type EdgeDirection
    = Directed
    | Undirected


type EdgeKind
    = WikiLinkEdge
    | TagEdge


type alias Summary =
    { publishedPageSlugs : List Page.Slug
    , missingPageSlugs : List Page.Slug
    , edges : List Edge
    }


summary : Wiki.Slug -> Dict Page.Slug String -> Dict Page.Slug (List Page.Slug) -> Summary
summary wikiSlug publishedPageMarkdownSources publishedPageTags =
    let
        publishedPageSlugs : List Page.Slug
        publishedPageSlugs =
            publishedPageMarkdownSources
                |> Dict.keys
                |> List.sortBy String.toLower

        publishedSlugSet : Set.Set String
        publishedSlugSet =
            publishedPageSlugs
                |> List.map String.toLower
                |> Set.fromList

        wikiLinkEdges : List Edge
        wikiLinkEdges =
            publishedPageMarkdownSources
                |> Dict.toList
                |> List.sortBy (Tuple.first >> String.toLower)
                |> List.concatMap
                    (\( fromPageSlug, markdown ) ->
                        PageLinkRefs.linkedPageSlugs wikiSlug markdown
                            |> List.sortBy String.toLower
                            |> List.map
                                (\toPageSlug ->
                                    { fromPageSlug = fromPageSlug
                                    , toPageSlug = toPageSlug
                                    , direction = Directed
                                    , targetPublished = Set.member (String.toLower toPageSlug) publishedSlugSet
                                    , kind = WikiLinkEdge
                                    }
                                )
                    )

        tagEdges : List Edge
        tagEdges =
            publishedPageTags
                |> Dict.toList
                |> List.sortBy (Tuple.first >> String.toLower)
                |> List.concatMap
                    (\( fromPageSlug, tags ) ->
                        tags
                            |> List.sortBy String.toLower
                            |> List.map
                                (\toPageSlug ->
                                    { fromPageSlug = fromPageSlug
                                    , toPageSlug = toPageSlug
                                    , direction = Directed
                                    , targetPublished = Set.member (String.toLower toPageSlug) publishedSlugSet
                                    , kind = TagEdge
                                    }
                                )
                    )

        edges : List Edge
        edges =
            List.append wikiLinkEdges tagEdges
                |> normalizeEdges

        missingPageSlugs : List Page.Slug
        missingPageSlugs =
            edges
                |> List.filter (\edge -> not edge.targetPublished)
                |> List.foldl
                    (\edge acc ->
                        let
                            normalized : String
                            normalized =
                                String.toLower edge.toPageSlug
                        in
                        if Dict.member normalized acc then
                            acc

                        else
                            Dict.insert normalized edge.toPageSlug acc
                    )
                    Dict.empty
                |> Dict.values
                |> List.sortBy String.toLower
    in
    { publishedPageSlugs = publishedPageSlugs
    , missingPageSlugs = missingPageSlugs
    , edges = edges
    }


dot : Wiki.Slug -> Dict Page.Slug String -> Dict Page.Slug (List Page.Slug) -> String
dot wikiSlug publishedPageMarkdownSources publishedPageTags =
    let
        graphSummary : Summary
        graphSummary =
            summary wikiSlug publishedPageMarkdownSources publishedPageTags

        graphAttrsLines : List String
        graphAttrsLines =
            [ "  layout=neato;"
            , "  overlap=" ++ dotString "prism" ++ ";"
            , "  overlap_scaling=1;"
            , "  sep=" ++ dotString "+6" ++ ";"
            , "  esep=" ++ dotString "+2" ++ ";"
            , "  splines=true;"
            , "  mode=major;"
            , "  model=" ++ dotString "shortpath" ++ ";"
            , "  start=" ++ dotString "random42" ++ ";"
            , "  epsilon=0.0001;"
            , "  maxiter=2000;"
            , "  pad=" ++ dotString "0.2" ++ ";"
            , "  concentrate=true;"
            , "  bgcolor=" ++ dotString "transparent" ++ ";"
            ]

        nodeAttrsLine : String
        nodeAttrsLine =
            "  node [shape=box"
                ++ ", fontname="
                ++ dotString "'Source Serif 4', system-ui, sans-serif"
                ++ ", fontsize="
                ++ dotString "11"
                ++ ", margin="
                ++ dotString "0.18,0.08"
                ++ ", height=0.3"
                ++ ", penwidth=1"
                ++ "];"

        edgeAttrsLine : String
        edgeAttrsLine =
            "  edge [color="
                ++ dotString "#6b7280"
                ++ ", arrowsize=0.7"
                ++ ", penwidth=0.9"
                ++ ", len=0.9"
                ++ "];"

        nodeLine : Page.Slug -> String
        nodeLine pageSlug =
            "  "
                ++ dotString pageSlug
                ++ " [href="
                ++ dotString (Wiki.pageGraphUrlPath wikiSlug pageSlug)
                ++ "];"

        missingNodeLine : Page.Slug -> String
        missingNodeLine pageSlug =
            "  "
                ++ dotString pageSlug
                ++ " [href="
                ++ dotString (Wiki.pageGraphUrlPath wikiSlug pageSlug)
                ++ ", style="
                ++ dotString "dashed"
                ++ ", color="
                ++ dotString "#dc2626"
                ++ ", fontcolor="
                ++ dotString "#dc2626"
                ++ "];"

        edgeLine : Edge -> String
        edgeLine edge =
            "  "
                ++ dotString edge.fromPageSlug
                ++ " -> "
                ++ dotString edge.toPageSlug
                ++ (case edge.kind of
                        WikiLinkEdge ->
                            case edge.direction of
                                Directed ->
                                    ";"

                                Undirected ->
                                    " [dir=none];"

                        TagEdge ->
                            " [style="
                                ++ dotString "dashed"
                                ++ ", color="
                                ++ dotString "#7c3aed"
                                ++ (case edge.direction of
                                        Directed ->
                                            "];"

                                        Undirected ->
                                            ", dir=none];"
                                   )
                   )
    in
    String.join "\n"
        (List.concat
            [ [ "digraph wiki {" ]
            , graphAttrsLines
            , [ nodeAttrsLine
              , edgeAttrsLine
              ]
            , List.map nodeLine graphSummary.publishedPageSlugs
            , List.map missingNodeLine graphSummary.missingPageSlugs
            , List.map edgeLine graphSummary.edges
            , [ "}" ]
            ]
        )


dotString : String -> String
dotString raw =
    "\""
        ++ (raw
                |> String.replace "\\" "\\\\"
                |> String.replace "\"" "\\\""
                |> String.replace "\n" "\\n"
           )
        ++ "\""


normalizeEdges : List Edge -> List Edge
normalizeEdges rawEdges =
    let
        rawLookup : Dict String Edge
        rawLookup =
            rawEdges
                |> List.sortBy edgeSortKey
                |> List.foldl
                    (\edge acc -> Dict.insert (directedEdgeKey edge) edge acc)
                    Dict.empty

        normalizedLookup : Dict String Edge
        normalizedLookup =
            rawLookup
                |> Dict.values
                |> List.sortBy edgeSortKey
                |> List.foldl
                    (\edge acc ->
                        let
                            normalizedEdge : Edge
                            normalizedEdge =
                                if edge.fromPageSlug /= edge.toPageSlug && Dict.member (reverseDirectedEdgeKey edge) rawLookup then
                                    undirectedEdge edge

                                else
                                    edge

                            normalizedKey : String
                            normalizedKey =
                                case normalizedEdge.direction of
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


undirectedEdge : Edge -> Edge
undirectedEdge edge =
    let
        ( canonicalFrom, canonicalTo ) =
            canonicalPair edge.fromPageSlug edge.toPageSlug
    in
    { fromPageSlug = canonicalFrom
    , toPageSlug = canonicalTo
    , direction = Undirected
    , targetPublished = True
    , kind = edge.kind
    }


canonicalPair : Page.Slug -> Page.Slug -> ( Page.Slug, Page.Slug )
canonicalPair left right =
    if slugSortKey left <= slugSortKey right then
        ( left, right )

    else
        ( right, left )


edgeSortKey : Edge -> String
edgeSortKey edge =
    kindSortKey edge.kind
        ++ "|"
        ++ slugSortKey edge.fromPageSlug
        ++ "|"
        ++ slugSortKey edge.toPageSlug
        ++ "|"
        ++ directionSortKey edge.direction


kindSortKey : EdgeKind -> String
kindSortKey kind =
    case kind of
        WikiLinkEdge ->
            "0"

        TagEdge ->
            "1"


directionSortKey : EdgeDirection -> String
directionSortKey direction =
    case direction of
        Directed ->
            "0"

        Undirected ->
            "1"


slugSortKey : Page.Slug -> String
slugSortKey pageSlug =
    String.toLower pageSlug ++ "|" ++ pageSlug


directedEdgeKey : Edge -> String
directedEdgeKey edge =
    kindSortKey edge.kind
        ++ "|"
        ++ slugSortKey edge.fromPageSlug
        ++ "|"
        ++ slugSortKey edge.toPageSlug


reverseDirectedEdgeKey : Edge -> String
reverseDirectedEdgeKey edge =
    kindSortKey edge.kind
        ++ "|"
        ++ slugSortKey edge.toPageSlug
        ++ "|"
        ++ slugSortKey edge.fromPageSlug


undirectedEdgeKey : Edge -> String
undirectedEdgeKey edge =
    let
        ( canonicalFrom, canonicalTo ) =
            canonicalPair edge.fromPageSlug edge.toPageSlug
    in
    kindSortKey edge.kind
        ++ "|"
        ++ slugSortKey canonicalFrom
        ++ "|"
        ++ slugSortKey canonicalTo
