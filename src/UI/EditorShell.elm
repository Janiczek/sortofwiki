module UI.EditorShell exposing (view)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as Events
import TW
import WikiMarkdownEditorPane exposing (WikiMarkdownEditorPane(..))


{-| Outer card for submit-new / submit-edit markdown editor (`Frontend` wiki flows).
-}
containerClass : String
containerClass =
    "flex flex-col h-full min-h-0 w-full overflow-hidden"


{-| Top field row (slug, tags, …) inside editor chrome.
-}
controlsRowClass : String
controlsRowClass =
    "shrink-0 px-4 py-3 border-b border-[var(--border-subtle)] bg-[var(--bg)] flex flex-wrap gap-3 items-end"


{-| Two-column editor + preview grid below the toolbar (desktop).
-}
contentGridClass : String
contentGridClass =
    "grid min-h-0 flex-1 w-full grid-cols-2 divide-x divide-[var(--border-subtle)]"


contentGridTabsClass : String
contentGridTabsClass =
    "grid min-h-0 flex-1 w-full grid-cols-1 md:grid-cols-2 md:divide-x divide-[var(--border-subtle)]"


tabStripClass : String
tabStripClass =
    "flex shrink-0 md:hidden border-b border-[var(--border-subtle)] bg-[var(--chrome-bg)]"


tabButtonClass : Bool -> String
tabButtonClass isActive =
    if isActive then
        "flex-1 px-3 py-2.5 text-[0.8125rem] font-semibold text-[var(--fg)] border-b-2 border-[var(--btn-bg)] [font-family:var(--font-ui)]"

    else
        "flex-1 px-3 py-2.5 text-[0.8125rem] font-medium text-[var(--fg-muted)] border-b-2 border-transparent hover:text-[var(--fg)] [font-family:var(--font-ui)]"


columnClassesForTabs : WikiMarkdownEditorPane -> Bool -> String
columnClassesForTabs activePane isEditorColumn =
    case ( activePane, isEditorColumn ) of
        ( EditorPreview, True ) ->
            "hidden md:flex md:flex-col md:min-h-0 md:h-full md:flex-1 min-w-0 h-full flex-1"

        ( EditorWrite, False ) ->
            "hidden md:flex md:flex-col md:min-h-0 md:h-full md:flex-1 min-w-0 h-full flex-1"

        ( EditorPreview, False ) ->
            "flex flex-col min-h-0 h-full min-w-0 flex-1"

        ( EditorWrite, True ) ->
            "flex flex-col min-h-0 h-full min-w-0 flex-1"


type alias MarkdownTabs msg =
    { activePane : WikiMarkdownEditorPane
    , onSelectPane : WikiMarkdownEditorPane -> msg
    }


viewTabsHeader : MarkdownTabs msg -> Html msg
viewTabsHeader tabs =
    Html.div [ TW.cls tabStripClass, Attr.attribute "role" "tablist" ]
        [ Html.button
            [ Attr.type_ "button"
            , Attr.attribute "role" "tab"
            , Events.onClick (tabs.onSelectPane EditorWrite)
            , TW.cls (tabButtonClass (tabs.activePane == EditorWrite))
            , Attr.attribute "aria-selected"
                (if tabs.activePane == EditorWrite then
                    "true"

                 else
                    "false"
                )
            ]
            [ Html.text "Write" ]
        , Html.button
            [ Attr.type_ "button"
            , Attr.attribute "role" "tab"
            , Events.onClick (tabs.onSelectPane EditorPreview)
            , TW.cls (tabButtonClass (tabs.activePane == EditorPreview))
            , Attr.attribute "aria-selected"
                (if tabs.activePane == EditorPreview then
                    "true"

                 else
                    "false"
                )
            ]
            [ Html.text "Preview" ]
        ]


view :
    { containerAttrs : List (Attribute msg)
    , controlsAttrs : List (Attribute msg)
    , controlsChildren : List (Html msg)
    , contentAttrs : List (Attribute msg)
    , contentChildren : List (Html msg)
    , maybeMarkdownTabs : Maybe (MarkdownTabs msg)
    }
    -> Html msg
view cfg =
    let
        contentRegion : Html msg
        contentRegion =
            case ( cfg.maybeMarkdownTabs, cfg.contentChildren ) of
                ( Just tabs, [ editorCol, previewCol ] ) ->
                    Html.div [ TW.cls "flex min-h-0 h-full w-full flex-1 flex-col overflow-hidden" ]
                        [ viewTabsHeader tabs
                        , Html.div
                            [ TW.cls contentGridTabsClass
                            , Attr.attribute "role" "presentation"
                            ]
                            [ Html.div [ TW.cls (columnClassesForTabs tabs.activePane True) ]
                                [ editorCol ]
                            , Html.div [ TW.cls (columnClassesForTabs tabs.activePane False) ]
                                [ previewCol ]
                            ]
                        ]

                _ ->
                    Html.div (TW.cls contentGridClass :: cfg.contentAttrs)
                        cfg.contentChildren
    in
    Html.div
        (TW.cls containerClass :: cfg.containerAttrs)
        [ if List.isEmpty cfg.controlsChildren then
            Html.text ""

          else
            Html.div
                (TW.cls controlsRowClass :: cfg.controlsAttrs)
                cfg.controlsChildren
        , contentRegion
        ]
