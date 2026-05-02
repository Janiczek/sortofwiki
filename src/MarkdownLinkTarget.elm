module MarkdownLinkTarget exposing (attrsIfOutsideHttp)

import Html
import Html.Attributes as Attr
import Url exposing (Url)


{-| For absolute `http`/`https` (or protocol-relative `//`) links whose origin differs from `currentUrl`,
add `target="_blank"` and `rel="noopener noreferrer"`.
Relative URLs and same-origin absolute URLs get no extra attributes.
-}
attrsIfOutsideHttp : Url -> String -> List (Html.Attribute msg)
attrsIfOutsideHttp currentUrl destination =
    if isCrossOriginHttpUrl currentUrl destination then
        [ Attr.target "_blank"
        , Attr.rel "noopener noreferrer"
        ]

    else
        []


isCrossOriginHttpUrl : Url -> String -> Bool
isCrossOriginHttpUrl currentUrl destination =
    case resolveAbsoluteHttpUrl currentUrl destination of
        Just absolute ->
            not (sameOrigin currentUrl absolute)

        Nothing ->
            False


sameOrigin : Url -> Url -> Bool
sameOrigin a b =
    a.protocol
        == b.protocol
        && String.toLower a.host
        == String.toLower b.host
        && a.port_
        == b.port_


resolveAbsoluteHttpUrl : Url -> String -> Maybe Url
resolveAbsoluteHttpUrl currentUrl rawDestination =
    let
        trimmed : String
        trimmed =
            String.trim rawDestination
    in
    if trimmed == "" then
        Nothing

    else if String.startsWith "http://" trimmed || String.startsWith "https://" trimmed then
        Url.fromString trimmed

    else if String.startsWith "//" trimmed then
        Url.fromString (protocolToString currentUrl.protocol ++ ":" ++ trimmed)

    else
        Nothing


protocolToString : Url.Protocol -> String
protocolToString protocol =
    case protocol of
        Url.Http ->
            "http"

        Url.Https ->
            "https"
