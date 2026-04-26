module Chapters.Graph exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import GraphData
import Html
import Html.Attributes as Attr
import UI.Graph


type EdgeKind
    = LinkEdge
    | TagEdge


type alias ExampleEdge =
    { fromSlug : String
    , toSlug : String
    , direction : GraphData.EdgeDirection
    , kind : EdgeKind
    }


chapter_ : Chapter x
chapter_ =
    chapter "UI.Graph"
        |> renderComponentList
            [ ( "UI.Graph.viewGraphviz (rendered graph)"
              , Html.div
                    [ Attr.style "min-height" "24rem"
                    , Attr.style "padding" "0.5rem"
                    ]
                    [ UI.Graph.view
                        { id = "book-graphviz-preview"
                        , graph =
                            { graphName = "book_graph"
                            , nodes =
                                [ node "Alpha" "/alpha" 8 False
                                , node "Beta" "/beta" 2 False
                                , node "Missing Node" "/missing" 1 True
                                ]
                            , edges =
                                [ edgeToUi { fromSlug = "Alpha", toSlug = "Beta", direction = GraphData.Directed, kind = LinkEdge }
                                , edgeToUi { fromSlug = "Alpha", toSlug = "Missing Node", direction = GraphData.Directed, kind = TagEdge }
                                ]
                            }
                        , attrs = []
                        }
                    ]
              )
            , ( "GraphData.normalizeEdges (bidirectional links become undirected)"
              , Html.pre []
                    [ Html.text normalizedEdgesPreview
                    ]
              )
            ]


exampleDot : String
exampleDot =
    UI.Graph.toDot
        { graphName = "book_graph"
        , nodes =
            [ node "Alpha" "/alpha" 8 False
            , node "Beta" "/beta" 2 False
            , node "Missing Node" "/missing" 1 True
            ]
        , edges =
            [ edgeToUi { fromSlug = "Alpha", toSlug = "Beta", direction = GraphData.Directed, kind = LinkEdge }
            , edgeToUi { fromSlug = "Alpha", toSlug = "Missing Node", direction = GraphData.Directed, kind = TagEdge }
            ]
        }


node : String -> String -> Int -> Bool -> UI.Graph.Node
node id href inboundCount isMissing =
    { id = id
    , href = href
    , inboundCount = inboundCount
    , kind =
        if isMissing then
            UI.Graph.MissingNode

        else
            UI.Graph.NormalNode
    }


normalizedEdgesPreview : String
normalizedEdgesPreview =
    [ { fromSlug = "Alpha", toSlug = "Beta", direction = GraphData.Directed, kind = LinkEdge }
    , { fromSlug = "Beta", toSlug = "Alpha", direction = GraphData.Directed, kind = LinkEdge }
    , { fromSlug = "Alpha", toSlug = "Tag", direction = GraphData.Directed, kind = TagEdge }
    ]
        |> GraphData.normalizeEdges
            { fromSlug = .fromSlug
            , toSlug = .toSlug
            , direction = .direction
            , kindSortKey = .kind >> edgeKindSortKey
            , toUndirected =
                \pair normalizedEdge ->
                    { normalizedEdge
                        | fromSlug = pair.canonicalFrom
                        , toSlug = pair.canonicalTo
                        , direction = GraphData.Undirected
                    }
            }
        |> List.map edgeToString
        |> String.join "\n"


edgeToUi : ExampleEdge -> UI.Graph.Edge
edgeToUi exampleEdge =
    { from = exampleEdge.fromSlug
    , to = exampleEdge.toSlug
    , direction = toUiDirection exampleEdge.direction
    , kind =
        case exampleEdge.kind of
            LinkEdge ->
                UI.Graph.LinkEdge

            TagEdge ->
                UI.Graph.TagEdge
    }


toUiDirection : GraphData.EdgeDirection -> UI.Graph.EdgeDirection
toUiDirection direction =
    case direction of
        GraphData.Directed ->
            UI.Graph.Directed

        GraphData.Undirected ->
            UI.Graph.Undirected


edgeKindSortKey : EdgeKind -> String
edgeKindSortKey kind =
    case kind of
        LinkEdge ->
            "0"

        TagEdge ->
            "1"


edgeToString : ExampleEdge -> String
edgeToString edge =
    edge.fromSlug
        ++ " -> "
        ++ edge.toSlug
        ++ " ("
        ++ (case edge.kind of
                LinkEdge ->
                    "link"

                TagEdge ->
                    "tag"
           )
        ++ ", "
        ++ (case edge.direction of
                GraphData.Directed ->
                    "directed"

                GraphData.Undirected ->
                    "undirected"
           )
        ++ ")"
