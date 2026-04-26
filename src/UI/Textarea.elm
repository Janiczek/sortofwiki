module UI.Textarea exposing
    ( compact
    , default
    , form
    , formCompact
    , markdownEditableCell
    , markdownReadonly
    , markdownReadonlyCell
    , markdownReadonlyCol1Row2
    , markdownReadonlyGridCol2Row2
    , markdownReadonlyWithExtra
    , positionedGridCol1Row3
    , positionedGridCol2Row3
    )

import Html exposing (Attribute)
import TW
import UI.FocusVisible


{-| Border, spacing, and width shared by textarea variants.
-}
formChromeClass : String
formChromeClass =
    "box-border px-[0.5rem] py-[0.3rem] mt-[0.1rem] mb-[0.2rem] rounded-lg border border-[var(--border-subtle)] bg-[var(--input-bg)] text-[var(--fg)] max-w-full w-full max-w-[48rem]"


{-| Shared typography plus textarea chrome.
-}
formShellClass : String
formShellClass =
    "[font-family:var(--font-ui)] text-[0.8125rem] " ++ formChromeClass


{-| Default tall multi-line control.
-}
formClass : String
formClass =
    formShellClass ++ " min-h-[5rem]"


{-| Short textarea inside flex layouts.
-}
formCompactClass : String
formCompactClass =
    formShellClass ++ " min-h-0"


{-| Markdown source textarea typography.
-}
markdownClass : String
markdownClass =
    "[font-family:var(--font-mono)] [font-variant-ligatures:none] text-[0.85rem] leading-[1.4]"


markdownPanelBaseClass : String
markdownPanelBaseClass =
    markdownClass
        ++ " box-border m-0 min-h-[12rem] max-h-[24rem] w-full flex-1 overflow-scroll [scrollbar-gutter:stable] bg-[var(--input-bg)] p-2 whitespace-pre-wrap break-words"


markdownPanelReadonlyClass : String
markdownPanelReadonlyClass =
    markdownPanelBaseClass
        ++ " cursor-default resize-none text-[color:color-mix(in_srgb,var(--fg)_50%,transparent)]"


markdownPanelEditableClass : String
markdownPanelEditableClass =
    markdownPanelBaseClass ++ " resize-none text-[var(--fg)]"


markdownPanelCellClass : String
markdownPanelCellClass =
    " h-full min-h-0 flex-1"


markdownReadonlyWithExtra : String -> List (Attribute msg) -> List (Attribute msg)
markdownReadonlyWithExtra extraClass attrs =
    TW.cls (markdownPanelReadonlyClass ++ extraClass) :: attrs


default : List (Attribute msg) -> List (Attribute msg)
default attrs =
    form attrs


compact : List (Attribute msg) -> List (Attribute msg)
compact attrs =
    formCompact attrs


form : List (Attribute msg) -> List (Attribute msg)
form attrs =
    UI.FocusVisible.on (TW.cls formClass :: attrs)


formCompact : List (Attribute msg) -> List (Attribute msg)
formCompact attrs =
    UI.FocusVisible.on (TW.cls formCompactClass :: attrs)


markdownEditableCell : List (Attribute msg) -> List (Attribute msg)
markdownEditableCell attrs =
    TW.cls (markdownPanelEditableClass ++ markdownPanelCellClass) :: attrs


positionedGridCol1Row3 : List (Attribute msg) -> List (Attribute msg)
positionedGridCol1Row3 attrs =
    TW.cls "min-h-0 min-w-0 col-start-1 row-start-3" :: attrs


positionedGridCol2Row3 : List (Attribute msg) -> List (Attribute msg)
positionedGridCol2Row3 attrs =
    TW.cls "min-h-0 min-w-0 col-start-2 row-start-3" :: attrs


markdownReadonlyGridCol2Row2 : List (Attribute msg) -> List (Attribute msg)
markdownReadonlyGridCol2Row2 attrs =
    TW.cls
        (markdownPanelReadonlyClass
            ++ markdownPanelCellClass
            ++ " min-w-0 col-start-2 row-start-2"
        )
        :: attrs


markdownReadonlyCol1Row2 : List (Attribute msg) -> List (Attribute msg)
markdownReadonlyCol1Row2 attrs =
    TW.cls
        (markdownPanelReadonlyClass
            ++ markdownPanelCellClass
            ++ " min-w-0 col-start-1 row-start-2"
        )
        :: attrs


markdownReadonly : List (Attribute msg) -> List (Attribute msg)
markdownReadonly attrs =
    TW.cls (markdownPanelReadonlyClass ++ "") :: attrs


markdownReadonlyCell : List (Attribute msg) -> List (Attribute msg)
markdownReadonlyCell attrs =
    TW.cls (markdownPanelReadonlyClass ++ markdownPanelCellClass) :: attrs
