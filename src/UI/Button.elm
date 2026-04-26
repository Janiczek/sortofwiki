module UI.Button exposing
    ( button
    , dangerButton
    , iconGhostButton
    , inlineLinkButton
    , secondaryButton
    , toggleChip
    )

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as Events
import TW
import UI.FocusVisible


class : String
class =
    "[font-family:inherit] text-[0.8125rem] font-bold tracking-[0.01em] px-[0.875rem] py-[0.4rem] mt-[0.1rem] mr-[0.15rem] mb-[0.1rem] ml-0 rounded-lg bg-[var(--btn-bg)] text-[var(--btn-fg)] border border-[var(--btn-border)] cursor-pointer hover:bg-[var(--btn-bg-hover)] dark:hover:border-[var(--border-dash)] disabled:opacity-[0.55] disabled:cursor-not-allowed"


{-| Filled destructive control. Uses `--danger-btn-bg` / `--danger-btn-fg` (not `--danger`) so class-based `.dark` matches CSS variables; see `head.html`.
-}
dangerClass : String
dangerClass =
    "[font-family:inherit] text-[0.8125rem] font-bold tracking-[0.01em] px-[0.875rem] py-[0.4rem] mt-[0.1rem] mr-[0.15rem] mb-[0.1rem] ml-0 rounded-lg bg-[var(--danger-btn-bg)] text-[var(--danger-btn-fg)] border border-[var(--danger-btn-bg)] cursor-pointer hover:brightness-[1.12] disabled:opacity-[0.55] disabled:cursor-not-allowed"


secondaryClass : String
secondaryClass =
    "[font-family:inherit] text-[0.8125rem] font-medium tracking-[0.01em] px-[0.875rem] py-[0.4rem] mt-[0.1rem] mr-[0.15rem] mb-[0.1rem] ml-0 rounded-lg bg-transparent text-[var(--fg-muted)] border border-[var(--border-subtle)] cursor-pointer hover:text-[var(--fg)] hover:bg-[var(--chrome-bg-hover)] disabled:opacity-[0.55] disabled:cursor-not-allowed"


button : List (Attribute msg) -> List (Html msg) -> Html msg
button attrs children =
    Html.button (UI.FocusVisible.on (TW.cls class :: attrs)) children


secondaryButton : List (Attribute msg) -> List (Html msg) -> Html msg
secondaryButton attrs children =
    Html.button (UI.FocusVisible.on (TW.cls secondaryClass :: attrs)) children


dangerButton : List (Attribute msg) -> List (Html msg) -> Html msg
dangerButton attrs children =
    Html.button (UI.FocusVisible.on (TW.cls dangerClass :: attrs)) children


{-| Badge-style toggle (e.g. filter chips). Inactive = muted surface; active = green chip tokens in `head.html`.
-}
toggleChip : List (Attribute msg) -> { pressed : Bool, onClick : msg, label : String } -> Html msg
toggleChip extraAttrs { pressed, onClick, label } =
    let
        stateClass : String
        stateClass =
            if pressed then
                "bg-[var(--chip-on-bg)] text-[var(--chip-on-fg)] border-[var(--chip-on-border)] shadow-[inset_0_1px_0_rgba(255,255,255,0.12)]"

            else
                "bg-[var(--chip-off-bg)] text-[var(--chip-off-fg)] border-[var(--chip-off-border)] hover:bg-[var(--chrome-bg-hover)]"
    in
    Html.button
        (TW.cls
            ("[font-family:inherit] inline-flex items-center text-[0.8125rem] leading-snug px-[0.6rem] py-[0.3rem] border rounded-full font-medium "
                ++ "transition-[background-color,border-color,color] duration-100 cursor-pointer "
                ++ "focus-visible:outline focus-visible:outline-2 focus-visible:outline-[var(--focus-ring)] focus-visible:outline-offset-2 "
                ++ stateClass
            )
            :: Attr.type_ "button"
            :: Attr.attribute "aria-pressed"
                (if pressed then
                    "true"

                 else
                    "false"
                )
            :: Events.onClick onClick
            :: extraAttrs
        )
        [ Html.text label ]


iconGhostClass : String
iconGhostClass =
    "shrink-0 inline-flex items-center justify-center w-[2.35rem] h-[2.35rem] p-0 m-0 border-0 bg-transparent text-[var(--fg)] cursor-pointer hover:bg-[var(--chrome-bg-hover)]"


iconGhostButton : List (Attribute msg) -> List (Html msg) -> Html msg
iconGhostButton attrs children =
    Html.button (UI.FocusVisible.on (TW.cls iconGhostClass :: attrs)) children


inlineLinkButton : List (Attribute msg) -> List (Html msg) -> Html msg
inlineLinkButton attrs children =
    Html.button
        (UI.FocusVisible.on
            (TW.cls
                ("text-left bg-transparent border-0 p-0 [font-family:inherit] cursor-pointer "
                    ++ "text-[var(--link)] hover:text-[var(--link-hover)] hover:bg-[var(--link-bg-hover)] underline underline-offset-[2px]"
                )
                :: attrs
            )
        )
        children
