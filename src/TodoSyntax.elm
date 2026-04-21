module TodoSyntax exposing (Segment(..), segmentsFromPlainText, todoTextsFromPlainText)


type Segment
    = Plain String
    | Todo String


todoTextsFromPlainText : String -> List String
todoTextsFromPlainText text =
    segmentsFromPlainText text
        |> List.filterMap
            (\segment ->
                case segment of
                    Plain _ ->
                        Nothing

                    Todo todoText ->
                        Just todoText
            )


segmentsFromPlainText : String -> List Segment
segmentsFromPlainText content =
    segmentsHelp content []


todoOpener : String
todoOpener =
    "{TODO:"


segmentsHelp : String -> List Segment -> List Segment
segmentsHelp remaining acc =
    case String.indexes todoOpener remaining |> List.head of
        Nothing ->
            if remaining == "" then
                acc

            else
                acc ++ [ Plain remaining ]

        Just i ->
            let
                before : String
                before =
                    String.left i remaining

                inner : String
                inner =
                    String.dropLeft (i + String.length todoOpener) remaining

                acc1 : List Segment
                acc1 =
                    if before == "" then
                        acc

                    else
                        acc ++ [ Plain before ]
            in
            case parseTodoInner inner of
                Nothing ->
                    segmentsHelp (String.dropLeft (i + 1) remaining) (acc1 ++ [ Plain "{" ])

                Just parsed ->
                    segmentsHelp
                        (String.dropLeft (i + String.length todoOpener + parsed.consumed) remaining)
                        (acc1 ++ [ Todo parsed.text ])


type alias ParsedTodo =
    { text : String
    , consumed : Int
    }


parseTodoInner : String -> Maybe ParsedTodo
parseTodoInner s =
    case String.indexes "}" s |> List.head of
        Nothing ->
            Nothing

        Just closeIndex ->
            let
                todoText : String
                todoText =
                    String.left closeIndex s
                        |> String.trim
            in
            if todoText == "" then
                Nothing

            else
                Just
                    { text = todoText
                    , consumed = closeIndex + 1
                    }
