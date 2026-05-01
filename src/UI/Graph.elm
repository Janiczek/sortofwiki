module UI.Graph exposing
    ( Edge
    , EdgeDirection(..)
    , EdgeKind(..)
    , Graph
    , Node
    , NodeKind(..)
    , toDot
    , view
    )

import Html
import Html.Attributes as Attr


type alias Graph =
    { graphName : String
    , nodes : List Node
    , edges : List Edge
    }


type alias Node =
    { id : String
    , href : String
    , inboundCount : Int
    , kind : NodeKind
    }


type alias Edge =
    { from : String
    , to : String
    , direction : EdgeDirection
    , kind : EdgeKind
    }


type NodeKind
    = NormalNode
    | MissingNode
    | FocusedNode
    | MissingFocusedNode


type EdgeDirection
    = Directed
    | Undirected


type EdgeKind
    = LinkEdge
    | TagEdge


view :
    { id : String
    , graph : Graph
    , attrs : List (Html.Attribute msg)
    }
    -> Html.Html msg
view config =
    Html.node "graphviz-graph"
        ([ Attr.id config.id
         , Attr.attribute "graph" (toDot config.graph)
         ]
            ++ config.attrs
        )
        []


toDot : Graph -> String
toDot graph =
    renderDot
        { graphName = graph.graphName
        , nodeLines = List.map nodeLine graph.nodes
        , edgeLines = List.map edgeLine graph.edges
        }


nodeLine : Node -> String
nodeLine node =
    let
        basePenWidth : Float
        basePenWidth =
            nodePenWidth node.inboundCount

        penWidth : Float
        penWidth =
            case node.kind of
                FocusedNode ->
                    max 2 basePenWidth

                MissingFocusedNode ->
                    max 2 basePenWidth

                NormalNode ->
                    basePenWidth

                MissingNode ->
                    basePenWidth

        attrs : List String
        attrs =
            [ "href=" ++ dotString node.href
            , "height=" ++ formatFloat (nodeHeight node.inboundCount)
            , "fontsize=" ++ formatFloat (nodeFontSize node.inboundCount)
            , "penwidth=" ++ formatFloat penWidth
            ]
                ++ (case node.kind of
                        MissingNode ->
                            missingNodeAttrs

                        MissingFocusedNode ->
                            missingNodeAttrs

                        NormalNode ->
                            []

                        FocusedNode ->
                            []
                   )
    in
    "  "
        ++ dotString node.id
        ++ " ["
        ++ String.join ", " attrs
        ++ "];"


edgeLine : Edge -> String
edgeLine edge =
    let
        attrs : List String
        attrs =
            edgeAttrs edge

        attrsPart : String
        attrsPart =
            if List.isEmpty attrs then
                ";"

            else
                " [" ++ String.join ", " attrs ++ "];"
    in
    "  "
        ++ dotString edge.from
        ++ " -> "
        ++ dotString edge.to
        ++ attrsPart


edgeAttrs : Edge -> List String
edgeAttrs edge =
    let
        directionAttrs : List String
        directionAttrs =
            case edge.direction of
                Directed ->
                    []

                Undirected ->
                    [ "dir=none" ]
    in
    case edge.kind of
        LinkEdge ->
            directionAttrs

        TagEdge ->
            [ "style=" ++ dotString "dashed"
            , "color=" ++ dotString "#7c3aed"
            ]
                ++ directionAttrs


missingNodeAttrs : List String
missingNodeAttrs =
    [ "style=" ++ dotString "dashed"
    , "color=" ++ dotString "#dc2626"
    , "fontcolor=" ++ dotString "#dc2626"
    ]


nodePenWidth : Int -> Float
nodePenWidth inboundCount =
    1 + (2 * inboundScale inboundCount)


inboundScale : Int -> Float
inboundScale inboundCount =
    logBase 11 (toFloat inboundCount + 1)
        |> clamp 0 1


nodeHeight : Int -> Float
nodeHeight inboundCount =
    0.3 + (0.24 * inboundScale inboundCount)


nodeFontSize : Int -> Float
nodeFontSize inboundCount =
    9 + (8 * inboundScale inboundCount)


defaultGraphAttrs : String
defaultGraphAttrs =
    """
    bgcolor="transparent";
    layout=fdp;
    start=random1;
    maxiter=2000;
    mode=major;
    """


defaultNodeAttrsLine : String
defaultNodeAttrsLine =
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


defaultEdgeAttrsLine : String -> String
defaultEdgeAttrsLine graphName =
    let
        ( edgeLen, edgeWeight ) =
            if graphName == "page" then
                -- Page graph should allow longer links than wiki-wide graph.
                ( "0.45", "6" )

            else
                ( "0.24", "14" )
    in
    "  edge [color="
        ++ dotString "#6b7280"
        ++ ", arrowsize=0.7"
        ++ ", penwidth=0.9"
        ++ ", len="
        ++ edgeLen
        ++ ", weight="
        ++ edgeWeight
        ++ "];"


dotString : String -> String
dotString raw =
    "\""
        ++ (raw
                |> String.replace "\\" "\\\\"
                |> String.replace "\"" "\\\""
                |> String.replace "\n" "\\n"
           )
        ++ "\""


renderDot :
    { graphName : String
    , nodeLines : List String
    , edgeLines : List String
    }
    -> String
renderDot config =
    String.join "\n"
        (List.concat
            [ [ "digraph " ++ config.graphName ++ " {" ]
            , [ defaultGraphAttrs
              , defaultNodeAttrsLine
              , defaultEdgeAttrsLine config.graphName
              ]
            , config.edgeLines
            , config.nodeLines
            , [ "}" ]
            ]
        )


formatFloat : Float -> String
formatFloat value =
    value
        |> (\v -> toFloat (round (v * 100)) / 100)
        |> String.fromFloat
