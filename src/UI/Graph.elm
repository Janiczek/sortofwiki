module UI.Graph exposing
    ( Edge
    , EdgeDirection(..)
    , EdgeKind(..)
    , Graph
    , Node
    , NodeKind(..)
    , view
    )

import Html
import Html.Attributes as Attr
import Json.Encode as Encode


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
    , deemphasized : Bool
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
    Html.node "cola-graph"
        ([ Attr.id config.id
         , Attr.attribute "data-graph" (config.graph |> encode |> Encode.encode 0)
         ]
            ++ config.attrs
        )
        []


encode : Graph -> Encode.Value
encode graph =
    Encode.object
        [ ( "graphName", Encode.string graph.graphName )
        , ( "nodes", Encode.list encodeNode graph.nodes )
        , ( "edges", Encode.list encodeEdge graph.edges )
        ]


encodeNode : Node -> Encode.Value
encodeNode node =
    Encode.object
        [ ( "id", Encode.string node.id )
        , ( "href", Encode.string node.href )
        , ( "inboundCount", Encode.int node.inboundCount )
        , ( "kind", node.kind |> nodeKindToString |> Encode.string )
        ]


encodeEdge : Edge -> Encode.Value
encodeEdge edge =
    Encode.object
        [ ( "from", Encode.string edge.from )
        , ( "to", Encode.string edge.to )
        , ( "direction", edge.direction |> edgeDirectionToString |> Encode.string )
        , ( "kind", edge.kind |> edgeKindToString |> Encode.string )
        , ( "deemphasized", Encode.bool edge.deemphasized )
        ]


nodeKindToString : NodeKind -> String
nodeKindToString nodeKind =
    case nodeKind of
        NormalNode ->
            "normal"

        MissingNode ->
            "missing"

        FocusedNode ->
            "focused"

        MissingFocusedNode ->
            "missingFocused"


edgeDirectionToString : EdgeDirection -> String
edgeDirectionToString edgeDirection =
    case edgeDirection of
        Directed ->
            "directed"

        Undirected ->
            "undirected"


edgeKindToString : EdgeKind -> String
edgeKindToString edgeKind =
    case edgeKind of
        LinkEdge ->
            "link"

        TagEdge ->
            "tag"
