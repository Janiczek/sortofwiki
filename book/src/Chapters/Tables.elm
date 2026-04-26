module Chapters.Tables exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import UI
import UI.Button


chapter_ : Chapter x
chapter_ =
    chapter "Tables"
        |> renderComponentList
            [ ( "table — auto width, top-aligned"
              , UI.table UI.TableAuto
                    []
                    { theadAttrs = []
                    , headerRowAttrs = []
                    , headerAlign = UI.TableAlignTop
                    , headers =
                        [ UI.tableHeaderText "Name"
                        , UI.tableHeaderText "Status"
                        , UI.tableHeaderText "Date"
                        ]
                    , tbodyAttrs = []
                    , rows =
                        [ UI.trStriped []
                            [ UI.tableTd UI.TableAlignTop [] [ Html.text "Alice" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "Active" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "2024-01-01" ]
                            ]
                        , UI.trStriped []
                            [ UI.tableTd UI.TableAlignTop [] [ Html.text "Bob" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "Inactive" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "2024-02-15" ]
                            ]
                        , UI.trStriped []
                            [ UI.tableTd UI.TableAlignTop [] [ Html.text "Carol" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "Pending" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "2024-03-20" ]
                            ]
                        ]
                    }
              )
            , ( "table — middle-aligned, with action buttons"
              , UI.table UI.TableAuto
                    []
                    { theadAttrs = []
                    , headerRowAttrs = []
                    , headerAlign = UI.TableAlignMiddle
                    , headers =
                        [ UI.tableHeaderText "Name"
                        , UI.tableHeaderText "Actions"
                        ]
                    , tbodyAttrs = []
                    , rows =
                        [ Html.tr []
                            [ UI.tableTd UI.TableAlignMiddle [] [ Html.text "Item A" ]
                            , UI.tableTd UI.TableAlignMiddle
                                []
                                [ UI.Button.button [] [ Html.text "Edit" ]
                                , UI.Button.dangerButton [] [ Html.text "Delete" ]
                                ]
                            ]
                        , Html.tr []
                            [ UI.tableTd UI.TableAlignMiddle [] [ Html.text "Item B" ]
                            , UI.tableTd UI.TableAlignMiddle
                                []
                                [ UI.Button.button [] [ Html.text "Edit" ]
                                , UI.Button.dangerButton [] [ Html.text "Delete" ]
                                ]
                            ]
                        ]
                    }
              )
            , ( "table — full-width (TableFullMax72) with mono timestamps"
              , UI.table UI.TableFullMax72
                    []
                    { theadAttrs = []
                    , headerRowAttrs = []
                    , headerAlign = UI.TableAlignTop
                    , headers =
                        [ UI.tableHeaderText "Timestamp"
                        , UI.tableHeaderText "User"
                        , UI.tableHeaderText "Action"
                        ]
                    , tbodyAttrs = []
                    , rows =
                        [ UI.trStriped []
                            [ Html.td [ UI.tableCellMonoTimestampAttr ] [ Html.text "2024-01-01 10:30:00" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "alice@example.com" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "Created page" ]
                            ]
                        , UI.trStriped []
                            [ Html.td [ UI.tableCellMonoTimestampAttr ] [ Html.text "2024-01-02 14:15:22" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "bob@example.com" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "Edited page" ]
                            ]
                        ]
                    }
              )
            ]
