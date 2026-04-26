module Book exposing (main)

import Chapters.Admin as Admin
import Chapters.AsyncState as AsyncState
import Chapters.AppHeader as AppHeader
import Chapters.Button as Button
import Chapters.EditorShell as EditorShell
import Chapters.EmptyState as EmptyState
import Chapters.FormActionFooter as FormActionFooter
import Chapters.FormControls as FormControls
import Chapters.FocusVisible as FocusVisible
import Chapters.Graph as Graph
import Chapters.Heading as Heading
import Chapters.IconInput as IconInput
import Chapters.Link as Link
import Chapters.MarkdownElements as MarkdownElements
import Chapters.Navigation as Navigation
import Chapters.PanelHeader as PanelHeader
import Chapters.ResultNotice as ResultNotice
import Chapters.SidebarSection as SidebarSection
import Chapters.StatusBadge as StatusBadge
import Chapters.SubmissionActions as SubmissionActions
import Chapters.Tables as Tables
import Chapters.Textarea as Textarea
import Chapters.Typography as Typography
import Chapters.WikiComponents as WikiComponents
import ElmBook
import ElmBook.StatefulOptions
import ElmBook.ThemeOptions
import SharedState exposing (SharedState)


main : ElmBook.Book SharedState
main =
    ElmBook.book "UI.elm"
        |> ElmBook.withStatefulOptions
            [ ElmBook.StatefulOptions.initialState SharedState.initialState ]
        |> ElmBook.withThemeOptions
            [ ElmBook.ThemeOptions.useHashBasedNavigation
            , ElmBook.ThemeOptions.background "#fafaf2"
            , ElmBook.ThemeOptions.accent "#496731"
            , ElmBook.ThemeOptions.navBackground "#f4f4ec"
            , ElmBook.ThemeOptions.navAccent "#44483d"
            , ElmBook.ThemeOptions.navAccentHighlight "#36521f"
            ]
        |> ElmBook.withChapterGroups
            [ ( "Typography", [ Typography.chapter_ ] )
            , ( "Form Controls"
              , [ FormControls.chapter_
                , FormControls.chapterChips
                , Textarea.chapter_
                , Button.chapter_
                , FocusVisible.chapter_
                , Link.chapter_
                , IconInput.chapter_
                ]
              )
            , ( "UI Shell & Feedback"
              , [ EditorShell.chapter_
                , Heading.chapter_
                , StatusBadge.chapter_
                , PanelHeader.chapter_
                , FormActionFooter.chapter_
                , SubmissionActions.chapter_
                , ResultNotice.chapter_
                , EmptyState.chapter_
                , AsyncState.chapter_
                , SidebarSection.chapter_
                ]
              )
            , ( "Navigation & Sidebar", [ Navigation.chapter_ ] )
            , ( "Tables", [ Tables.chapter_ ] )
            , ( "App Header", [ AppHeader.chapter_ ] )
            , ( "Markdown", [ MarkdownElements.chapter_ ] )
            , ( "Wiki", [ WikiComponents.chapter_ ] )
            , ( "Graph", [ Graph.chapter_ ] )
            , ( "Admin & Audit"
              , [ Admin.chapter_
                , Admin.chapterAuditFilters
                , Admin.chapterSubmissionFlow
                ]
              )
            ]
