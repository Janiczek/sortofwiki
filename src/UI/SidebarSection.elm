module UI.SidebarSection exposing (section)

import Html as H exposing (Html)
import Html.Attributes as Attr
import TW
import UI.Heading


section :
    { id : String
    , title : String
    , body : Html msg
    }
    -> Html msg
section cfg =
    H.section
        [ Attr.id cfg.id
        , TW.cls "max-w-[52rem]"
        ]
        [ UI.Heading.sidebarHeading cfg.title
        , cfg.body 
        ]