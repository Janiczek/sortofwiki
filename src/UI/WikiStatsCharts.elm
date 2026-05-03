module UI.WikiStatsCharts exposing (viewDailyAccumulatedCharts, viewDailyActivityCharts)

{-| Wiki stats SVG charts (elm-charts). Keeps Chart/Chart.Attributes usage out of Frontend.
-}

import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE
import Chart.Item as CI
import Html exposing (Html)
import Html.Attributes as HA
import WikiStats


activityRowsToFloats : List { day : String, creates : Int, edits : Int, deletes : Int } -> List { day : String, creates : Float, edits : Float, deletes : Float }
activityRowsToFloats rows =
    rows
        |> List.map
            (\r ->
                { day = r.day
                , creates = toFloat r.creates
                , edits = toFloat r.edits
                , deletes = toFloat r.deletes
                }
            )


{-| Three separate compact bar charts (creates, edits, deletes).

Expects `dailyActivityCounts` sorted by `day` ascending (same as `WikiStats.buildFromAudit`).

-}
viewDailyActivityCharts :
    { hoveredBar : Maybe { metric : String, day : String, count : Int }
    , onHoverChange : Maybe { metric : String, day : String, count : Int } -> msg
    }
    -> List { day : String, creates : Int, edits : Int, deletes : Int }
    -> Html msg
viewDailyActivityCharts config rows =
    let
        chartRows : List { day : String, creates : Float, edits : Float, deletes : Float }
        chartRows =
            activityRowsToFloats rows
    in
    if List.isEmpty chartRows then
        Html.text ""

    else
        let
            sharedYMax : Float
            sharedYMax =
                let
                    peak : Float
                    peak =
                        chartRows
                            |> List.concatMap (\r -> [ r.creates, r.edits, r.deletes ])
                            |> List.maximum
                            |> Maybe.withDefault 0
                in
                max peak 1
        in
        Html.div
            [ HA.class "grid grid-cols-1 gap-2 md:grid-cols-3"
            , HA.style "width" "100%"
            ]
            [ compactMetricChart "Creates"
                "var(--chip-on-bg)"
                sharedYMax
                (List.map (\r -> { day = r.day, value = r.creates }) chartRows)
                config.hoveredBar
                config.onHoverChange
            , compactMetricChart "Edits"
                "var(--link)"
                sharedYMax
                (List.map (\r -> { day = r.day, value = r.edits }) chartRows)
                config.hoveredBar
                config.onHoverChange
            , compactMetricChart "Deletes"
                "var(--danger-btn-bg)"
                sharedYMax
                (List.map (\r -> { day = r.day, value = r.deletes }) chartRows)
                config.hoveredBar
                config.onHoverChange
            ]


{-| Three bar charts: cumulative published pages, missing pages, and TODO items (replay from audit).
-}
viewDailyAccumulatedCharts :
    { hoveredBar : Maybe { metric : String, day : String, count : Int }
    , onHoverChange : Maybe { metric : String, day : String, count : Int } -> msg
    }
    -> List WikiStats.DailyAccumulatedSnapshot
    -> Html msg
viewDailyAccumulatedCharts config rows =
    if List.isEmpty rows then
        Html.text ""

    else
        let
            yMaxPublished : Float
            yMaxPublished =
                rows
                    |> List.map (.publishedPages >> toFloat)
                    |> List.maximum
                    |> Maybe.withDefault 0
                    |> max 1

            yMaxMissing : Float
            yMaxMissing =
                rows
                    |> List.map (.missingPages >> toFloat)
                    |> List.maximum
                    |> Maybe.withDefault 0
                    |> max 1

            yMaxTodos : Float
            yMaxTodos =
                rows
                    |> List.map (.todos >> toFloat)
                    |> List.maximum
                    |> Maybe.withDefault 0
                    |> max 1
        in
        Html.div
            [ HA.class "grid grid-cols-1 gap-2 md:grid-cols-3"
            , HA.style "width" "100%"
            ]
            [ compactMetricChart "Published pages (cumulative)"
                "var(--chip-on-bg)"
                yMaxPublished
                (List.map (\r -> { day = r.day, value = toFloat r.publishedPages }) rows)
                config.hoveredBar
                config.onHoverChange
            , compactMetricChart "Missing pages (cumulative)"
                "var(--danger-btn-bg)"
                yMaxMissing
                (List.map (\r -> { day = r.day, value = toFloat r.missingPages }) rows)
                config.hoveredBar
                config.onHoverChange
            , compactMetricChart "TODO items (cumulative)"
                "var(--danger-btn-bg)"
                yMaxTodos
                (List.map (\r -> { day = r.day, value = toFloat r.todos }) rows)
                config.hoveredBar
                config.onHoverChange
            ]


{-| Lighter bar fill when bin matches hover (same as `color-mix` elsewhere in this module).
-}
barFillHovered : String -> String
barFillHovered base =
    "color-mix(in srgb, " ++ base ++ " 62%, white)"


gridLineColor : String
gridLineColor =
    "color-mix(in srgb, var(--border-subtle) 18%, var(--bg))"


axisLineColor : String
axisLineColor =
    "color-mix(in srgb, var(--border-subtle) 55%, var(--bg))"


compactMetricChart :
    String
    -> String
    -> Float
    -> List { day : String, value : Float }
    -> Maybe { metric : String, day : String, count : Int }
    -> (Maybe { metric : String, day : String, count : Int } -> msg)
    -> Html msg
compactMetricChart title color yMax data maybeHover onHoverChange =
    let
        chartWidth : Int
        chartWidth =
            List.length data
                |> (\n -> max 260 (min 4000 (n * 4)))

        xTickAmount : Int
        xTickAmount =
            List.length data
                |> (\n -> max 4 (min 14 (n // 25 + 4)))

        hoverInfoText : String
        hoverInfoText =
            case maybeHover of
                Just hover ->
                    if hover.metric == title then
                        hover.day ++ ": " ++ String.fromInt hover.count

                    else
                        "Hover bar for day count"

                Nothing ->
                    "Hover bar for day count"

        -- `CE.getNearestX CI.bins`: nearest column by x only (full bin width), not distance to short bar geometry.
        hoverDecoder : List (CI.Many { day : String, value : Float } x) -> Maybe { metric : String, day : String, count : Int }
        hoverDecoder binsHit =
            binsHit
                |> List.head
                |> Maybe.map CI.getOneData
                |> Maybe.map
                    (\d ->
                        { metric = title
                        , day = d.day
                        , count = round d.value
                        }
                    )
    in
    Html.div
        [ HA.style "width" "100%" ]
        [ Html.div
            [ HA.style "font-size" "0.6875rem"
            , HA.style "font-weight" "600"
            , HA.style "color" "var(--fg-muted)"
            , HA.style "margin-bottom" "2px"
            , HA.style "letter-spacing" "0.02em"
            ]
            [ Html.text title ]
        , Html.div
            [ HA.style "font-size" "0.625rem"
            , HA.style "color" "var(--fg-subtle)"
            , HA.style "min-height" "0.9rem"
            ]
            [ Html.text hoverInfoText ]
        , Html.div
            [ HA.style "width" "100%"
            , HA.style "overflow-x" "auto"
            ]
            [ C.chart
                [ CA.width (toFloat chartWidth)
                , CA.height 168
                , CA.margin { top = 4, right = 14, bottom = 58, left = 26 }
                , CA.padding { top = 4, right = 2, bottom = 4, left = 4 }
                , CA.domain
                    [ CA.lowest 0 CA.exactly
                    , CA.highest yMax CA.exactly
                    ]
                , CA.htmlAttrs [ HA.style "display" "block" ]
                , CE.onMouseMove (hoverDecoder >> onHoverChange) (CE.getNearestX CI.bins)
                , CE.onMouseLeave (onHoverChange Nothing)
                ]
                [ C.xTicks [ CA.amount xTickAmount, CA.color axisLineColor ]
                , C.yTicks [ CA.amount 3, CA.color axisLineColor ]
                , C.yLabels [ CA.amount 3, CA.fontSize 7, CA.color "var(--fg-muted)" ]
                , C.xAxis [ CA.color axisLineColor, CA.noArrow ]
                , C.yAxis [ CA.color axisLineColor, CA.noArrow ]
                , C.grid [ CA.color gridLineColor ]
                , C.bars
                    [ CA.spacing 0.15
                    , CA.margin 0.18
                    , CA.roundTop 0.12
                    ]
                    [ C.bar .value [ CA.color color ]
                        |> C.variation
                            (\_ datum ->
                                case maybeHover of
                                    Just hover ->
                                        if hover.metric == title && hover.day == datum.day then
                                            [ CA.color (barFillHovered color) ]

                                        else
                                            []

                                    Nothing ->
                                        []
                            )
                    ]
                    data
                , C.binLabels .day
                    [ CA.moveDown 28
                    , CA.fontSize 7
                    , CA.color "var(--fg-muted)"
                    , CA.rotate -90
                    ]
                ]
            ]
        ]
