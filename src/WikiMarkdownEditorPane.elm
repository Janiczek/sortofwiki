module WikiMarkdownEditorPane exposing (WikiMarkdownEditorPane(..))

{-| Active pane for markdown submit/edit flows on narrow viewports (tabs). Desktop shows both columns.
-}


type WikiMarkdownEditorPane
    = EditorWrite
    | EditorPreview
