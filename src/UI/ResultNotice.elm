module UI.ResultNotice exposing (fromMaybeResult, fromResult)

import Html as H exposing (Html)
import Html.Attributes as Attr
import TW


fromResult :
    { id : String
    , okText : String
    , errToText : err -> String
    }
    -> Result err ok
    -> Html msg
fromResult cfg result =
    fromMaybeResult cfg (Just result)


{-| Map `Maybe (Result err ok)` to success / error banners.

`id` is prefix: success node id is `id ++ "-success"`, error outer id `id ++ "-error"`,
inner span id `id ++ "-error-text"`.

-}
fromMaybeResult :
    { id : String
    , okText : String
    , errToText : err -> String
    }
    -> Maybe (Result err ok)
    -> Html msg
fromMaybeResult cfg maybeResult =
    case maybeResult of
        Nothing ->
            H.text ""

        Just (Ok _) ->
            H.div
                [ Attr.id (cfg.id ++ "-success") ]
                [ contentParagraph [] [ H.text cfg.okText ] ]

        Just (Err e) ->
            H.div
                [ Attr.id (cfg.id ++ "-error") ]
                [ contentParagraph []
                    [ H.span
                        [ Attr.id (cfg.id ++ "-error-text") ]
                        [ H.text (cfg.errToText e) ]
                    ]
                ]


contentParagraph : List (H.Attribute msg) -> List (Html msg) -> Html msg
contentParagraph attrs children =
    H.p (TW.cls contentParagraphClass :: attrs) children


contentParagraphClass : String
contentParagraphClass =
    "my-[1rem] leading-[1.6] [font-family:var(--font-serif)] first:mt-0"
