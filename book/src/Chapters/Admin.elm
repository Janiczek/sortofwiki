module Chapters.Admin exposing (chapterAuditFilters, chapterSubmissionFlow, chapter_)

import ElmBook.Actions
import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import Html.Attributes as Attr
import TW
import UI
import UI.Button
import UI.StatusBadge
import UI.Textarea
import UI.Heading


chapter_ : Chapter x
chapter_ =
    chapter "Admin Components"
        |> renderComponentList
            [ ( "hostAdminWikiDetailCard"
              , Html.div [ UI.hostAdminWikiDetailCardAttr ]
                    [ UI.Heading.cardHeadingSm [] [ Html.text "Wiki Settings" ]
                    , Html.p [ UI.hostAdminCardParagraphTightAttr ]
                        [ Html.text "Manage this wiki's configuration and access controls." ]
                    , Html.div [ UI.hostAdminWikiDetailFormStackAttr ]
                        [ Html.label [ TW.cls "block text-[0.82rem] font-medium text-[var(--fg-muted)]" ]
                            [ Html.text "Slug" ]
                        , Html.input
                            [ UI.formTextInputHostAdminSlugAttr
                            , Attr.type_ "text"
                            , Attr.value "my-wiki"
                            ]
                            []
                        , UI.Button.button [] [ Html.text "Save" ]
                        ]
                    ]
              )
            , ( "hostAdminWikiDetailDangerCard"
              , Html.div [ UI.hostAdminWikiDetailDangerCardAttr ]
                    [ UI.Heading.cardHeadingDanger [] [ Html.text "Delete Wiki" ]
                    , Html.p [ UI.hostAdminDangerBlurbAttr ]
                        [ Html.text "Permanently deletes the wiki and all its pages. This cannot be undone." ]
                    , UI.Button.dangerButton [] [ Html.text "Delete this wiki" ]
                    ]
              )
            , ( "hostAdminWikiStatusBadge — active"
              , UI.StatusBadge.view { isActive = True, text = "Active" }
              )
            , ( "hostAdminWikiStatusBadge — inactive"
              , UI.StatusBadge.view { isActive = False, text = "Inactive" }
              )
            , ( "hostAdminWikiSlugClass (monospace slug)"
              , Html.p [ TW.cls UI.hostAdminWikiSlugClass ]
                    [ Html.text "my-elm-wiki-slug" ]
              )
            , ( "hostAdminBackupCard"
              , Html.div [ UI.hostAdminBackupCardAttr ]
                    [ UI.Heading.cardHeadingLg [] [ Html.text "Backups" ]
                    , Html.p [ UI.formFeedbackTextSmAttr ]
                        [ Html.text "Download a full backup of all wiki content as JSON." ]
                    , UI.Button.button [] [ Html.text "Download backup" ]
                    ]
              )
            , ( "hostAdminWikiDetail grid layout"
              , Html.div [ UI.hostAdminWikiDetailShellAttr ]
                    [ Html.h1 [ UI.hostAdminWikiDetailPageTitleAttr ]
                        [ Html.text "Wiki: My Elm Wiki" ]
                    , Html.div [ UI.hostAdminWikiDetailGridAttr ]
                        [ Html.div [ UI.hostAdminWikiDetailMainStackAttr ]
                            [ Html.div [ UI.hostAdminWikiDetailCardAttr ]
                                [ UI.Heading.cardHeadingSm [] [ Html.text "Configuration" ]
                                , Html.p [ UI.hostAdminStatusParaAttr ]
                                    [ Html.text "Status: "
                                    , UI.StatusBadge.view { isActive = True, text = "Active" }
                                    ]
                                ]
                            ]
                        , Html.div [ UI.hostAdminWikiDetailSideStackAttr ]
                            [ Html.div [ UI.hostAdminWikiDetailCardAttr ]
                                [ UI.Heading.cardHeadingSm [] [ Html.text "Quick Info" ]
                                , Html.p [ TW.cls UI.hostAdminWikiSlugClass ]
                                    [ Html.text "my-elm-wiki" ]
                                ]
                            ]
                        ]
                    ]
              )
            , ( "auditLogTableView (fixed-header scrolling table)"
              , UI.auditLogTableView
                    { tableId = "audit-demo"
                    , tbodyId = "audit-demo-body"
                    , columnClasses = [ "w-[12rem]", "w-[12rem]", "" ]
                    , headers = [ "Timestamp", "User", "Description" ]
                    , rows =
                        [ Html.tr []
                            [ Html.td [ UI.tableCellMonoTimestampAttr ] [ Html.text "2024-01-01 10:30" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "alice@example.com" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "Created page: Getting Started" ]
                            ]
                        , Html.tr []
                            [ Html.td [ UI.tableCellMonoTimestampAttr ] [ Html.text "2024-01-02 14:15" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "bob@example.com" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "Edited page: Introduction" ]
                            ]
                        , Html.tr []
                            [ Html.td [ UI.tableCellMonoTimestampAttr ] [ Html.text "2024-01-03 09:00" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "carol@example.com" ]
                            , UI.tableTd UI.TableAlignTop [] [ Html.text "Deleted page: Draft" ]
                            ]
                        ]
                    }
              )
            ]


chapterAuditFilters : Chapter x
chapterAuditFilters =
    chapter "Audit Filters"
        |> renderComponentList
            [ ( "hostAdminAuditFiltersCard — 3-column filter grid"
              , Html.div [ UI.hostAdminAuditFiltersCardAttr ]
                    [ Html.div [ UI.hostAdminAuditFiltersGridAttr ]
                        [ Html.div [ UI.formFieldMinW0Attr ]
                            [ Html.label [ UI.formFieldLabelBlockAttr ] [ Html.text "User" ]
                            , Html.input [ UI.formTextInputAuditFilterAttr, Attr.placeholder "Filter by user…" ] []
                            ]
                        , Html.div [ UI.formFieldMinW0Attr ]
                            [ Html.label [ UI.formFieldLabelBlockAttr ] [ Html.text "Page" ]
                            , Html.input [ UI.formTextInputAuditFilterAttr, Attr.placeholder "Filter by page…" ] []
                            ]
                        , Html.div [ UI.formFieldMinW0Attr ]
                            [ Html.label [ UI.formFieldLabelBlockAttr ] [ Html.text "Date" ]
                            , Html.input [ UI.formTextInputAuditFilterAttr, Attr.type_ "date" ] []
                            ]
                        ]
                    , Html.div [ UI.auditFilterTypeGroupAttr ]
                        [ Html.p [ UI.auditFilterLegendTextAttr ] [ Html.text "Filter by event type" ]
                        , Html.div [ UI.flexWrapGap2Attr ]
                            [ UI.Button.toggleChip []
                                { pressed = True
                                , onClick = ElmBook.Actions.logAction "chip: page-created toggled"
                                , label = "Page created"
                                }
                            , UI.Button.toggleChip []
                                { pressed = False
                                , onClick = ElmBook.Actions.logAction "chip: page-edited toggled"
                                , label = "Page edited"
                                }
                            , UI.Button.toggleChip []
                                { pressed = True
                                , onClick = ElmBook.Actions.logAction "chip: page-deleted toggled"
                                , label = "Page deleted"
                                }
                            ]
                        ]
                    ]
              )
            , ( "wikiAdminAuditFiltersGrid — 2-column variant"
              , Html.div [ UI.hostAdminAuditFiltersCardAttr ]
                    [ Html.div [ UI.wikiAdminAuditFiltersGridAttr ]
                        [ Html.div [ UI.formFieldMinW0Attr ]
                            [ Html.label [ UI.formFieldLabelBlockAttr ] [ Html.text "User" ]
                            , Html.input [ UI.formTextInputAuditFilterAttr, Attr.placeholder "Filter by user…" ] []
                            ]
                        , Html.div [ UI.formFieldMinW0Attr ]
                            [ Html.label [ UI.formFieldLabelBlockAttr ] [ Html.text "Page" ]
                            , Html.input [ UI.formTextInputAuditFilterAttr, Attr.placeholder "Filter by page…" ] []
                            ]
                        ]
                    ]
              )
            ]


chapterSubmissionFlow : Chapter x
chapterSubmissionFlow =
    chapter "Submission & Review Flow"
        |> renderComponentList
            [ ( "New page editor (markdown source + preview)"
              , Html.div [ UI.gridTwoColEditorStrAttr, Attr.style "min-height" "14rem" ]
                    [ Html.div [ UI.newPageEditorMarkdownPreviewCellAttr ]
                        [ UI.Heading.panelHeadingPrimary [] [ Html.text "Markdown" ]
                        , Html.textarea
                            (UI.Textarea.markdownEditableCell [])
                            [ Html.text "# New Page\n\nContent goes here." ]
                        ]
                    , Html.div [ UI.newPageEditorMarkdownPreviewCellAttr ]
                        [ UI.Heading.panelHeadingSecondary [] [ Html.text "Preview" ]
                        , Html.div [ UI.markdownPreviewScrollMinFlexAttr ]
                            [ Html.div [ TW.cls UI.markdownContainerClass ]
                                [ UI.Heading.markdownHeading1 [] [ Html.text "New Page" ]
                                , Html.p [ TW.cls UI.markdownParagraphClass ]
                                    [ Html.text "Content goes here." ]
                                ]
                            ]
                        ]
                    ]
              )
            , ( "Review diff — edit submission (before / after)"
              , Html.div [ UI.classAttr "grid min-w-0 grid-cols-2 grid-rows-[auto_auto_auto] gap-4 items-stretch", Attr.style "min-height" "14rem" ]
                    [ UI.Heading.gridHeadingCol1 [] [ Html.text "Before" ]
                    , UI.Heading.gridHeadingCol2 [] [ Html.text "After" ]
                    , Html.textarea
                        (UI.Textarea.markdownReadonlyCol1Row2 [ Attr.readonly True ])
                        [ Html.text "# Original Title\n\nOriginal content." ]
                    , Html.textarea
                        (UI.Textarea.markdownReadonlyGridCol2Row2 [ Attr.readonly True ])
                        [ Html.text "# New Title\n\nRevised content with changes." ]
                    , Html.div [ UI.gridCellStackCol1Row3Attr ]
                        [ UI.Heading.panelHeadingPrimary [] [ Html.text "Preview (before)" ]
                        , Html.div [ UI.markdownPreviewScrollMinFlexAttr ]
                            [ Html.div [ TW.cls UI.markdownContainerClass ]
                                [ UI.Heading.markdownHeading1 [] [ Html.text "Original Title" ]
                                , Html.p [ TW.cls UI.markdownParagraphClass ] [ Html.text "Original content." ]
                                ]
                            ]
                        ]
                    , Html.div [ UI.gridCellStackCol2Row3Attr ]
                        [ UI.Heading.panelHeadingPrimary [] [ Html.text "Preview (after)" ]
                        , Html.div [ UI.markdownPreviewScrollMinFlexAttr ]
                            [ Html.div [ TW.cls UI.markdownContainerClass ]
                                [ UI.Heading.markdownHeading1 [] [ Html.text "New Title" ]
                                , Html.p [ TW.cls UI.markdownParagraphClass ] [ Html.text "Revised content with changes." ]
                                ]
                            ]
                        ]
                    ]
              )
            , ( "Review diff — new page submission"
              , Html.div [ UI.classAttr "grid min-w-0 grid-cols-2 grid-rows-[auto_1fr] gap-4 items-stretch", Attr.style "min-height" "10rem" ]
                    [ UI.Heading.gridHeadingPrimaryCol1 [] [ Html.text "Proposed page" ]
                    , UI.Heading.gridHeadingSecondaryCol2 [] [ Html.text "Preview" ]
                    , Html.textarea
                        (UI.Textarea.markdownReadonlyCol1Row2 [ Attr.readonly True ])
                        [ Html.text "# A Brand New Page\n\nThis page doesn't exist yet." ]
                    , Html.div [ UI.reviewDiffNewPagePreviewColShellAttr ]
                        [ Html.div [ UI.markdownPreviewScrollMinFlexFullHeightAttr ]
                            [ Html.div [ TW.cls UI.markdownContainerClass ]
                                [ UI.Heading.markdownHeading1 [] [ Html.text "A Brand New Page" ]
                                , Html.p [ TW.cls UI.markdownParagraphClass ]
                                    [ Html.text "This page doesn't exist yet." ]
                                ]
                            ]
                        ]
                    ]
              )
            , ( "Review diff — delete page"
              , Html.div []
                    [ Html.p [ UI.reviewDeletePagePreviewTitleAttr ]
                        [ Html.text "Current published content (will be deleted):" ]
                    , Html.textarea
                        (UI.Textarea.markdownReadonly [ Attr.readonly True ])
                        [ Html.text "# Page to Delete\n\nThis content will be removed." ]
                    ]
              )
            , ( "Review decision fieldset"
              , Html.fieldset [ UI.reviewFieldsetAttr ]
                    [ Html.legend [ UI.reviewLegendAttr ] [ Html.text "Decision" ]
                    , Html.div [ UI.reviewRadioColumnAttr ]
                        [ Html.label [ UI.reviewRadioRowAttr ]
                            [ Html.input [ Attr.type_ "radio", Attr.name "decision-demo", Attr.checked True ] []
                            , Html.div []
                                [ Html.strong [ UI.reviewOptionLabelStrongAttr ] [ Html.text "Approve" ]
                                , Html.div [ UI.reviewNestedNoteColumnAttr ]
                                    [ Html.textarea
                                        (UI.Textarea.formCompact [ Attr.placeholder "Optional note for the contributor…" ])
                                        []
                                    ]
                                ]
                            ]
                        , Html.label [ UI.reviewRadioRowAttr ]
                            [ Html.input [ Attr.type_ "radio", Attr.name "decision-demo", Attr.checked False ] []
                            , Html.strong [ UI.reviewOptionLabelStrongAttr ] [ Html.text "Request changes" ]
                            ]
                        , Html.label [ UI.reviewRadioRowAttr ]
                            [ Html.input [ Attr.type_ "radio", Attr.name "decision-demo", Attr.checked False ] []
                            , Html.strong [ UI.reviewOptionLabelStrongAttr ] [ Html.text "Reject" ]
                            ]
                        ]
                    ]
              )
            , ( "Submission status + action bar"
              , Html.div []
                    [ Html.p [ UI.submitSummaryParagraphAttr ]
                        [ Html.text "This edit proposes changes to the introduction section." ]
                    , Html.div [ UI.submitActionsBarAttr ]
                        [ UI.Button.button [] [ Html.text "Submit edit" ]
                        , UI.Button.dangerButton [] [ Html.text "Discard" ]
                        ]
                    , Html.p [ UI.submissionStatusDangerLineAttr ]
                        [ Html.text "This submission conflicts with a recent edit." ]
                    ]
              )
            , ( "Submission conflict grid (2-col with preview)"
              , Html.div [ UI.submissionGridTight2ColAttr ]
                    [ Html.div []
                        [ Html.strong [ TW.cls "text-[0.82rem] text-[var(--fg-muted)]" ] [ Html.text "Your version" ] ]
                    , Html.div []
                        [ Html.strong [ TW.cls "text-[0.82rem] text-[var(--fg-muted)]" ] [ Html.text "Current published" ] ]
                    , Html.textarea
                        (UI.Textarea.markdownReadonlyCol1Row2 [ Attr.readonly True ])
                        [ Html.text "# My edits\n\nContent I wrote." ]
                    , Html.textarea
                        (UI.Textarea.markdownReadonlyWithExtra
                            " min-w-0 col-start-2 row-start-3"
                            [ Attr.readonly True ]
                        )
                        [ Html.text "# Published version\n\nContent that was published." ]
                    , Html.div [ UI.gridCellStackCol2Row3Attr ]
                        [ Html.div [ UI.classAttr UI.markdownPreviewScrollClass ]
                            [ Html.div [ TW.cls UI.markdownContainerClass ]
                                [ UI.Heading.markdownHeading1 [] [ Html.text "Published version" ]
                                , Html.p [ TW.cls UI.markdownParagraphClass ] [ Html.text "Content that was published." ]
                                ]
                            ]
                        ]
                    ]
              )
            ]
