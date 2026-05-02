module MarkdownInlineLinkUrls exposing (wrapParenContainingDestinations)

{-| [dillonkearns/elm-markdown](https://package.elm-lang.org/packages/dillonkearns/elm-markdown/latest/)
uses link destination regex that forbids raw `(` and `)` (unless angle-wrapped). Angle-wrapped URLs can overlap autolink
tokenization and yield nested links. Rewriting to percent-encoded `%28` / `%29` keeps one link and matches `hrefRegex`.

TODO: this will not be needed once
https://github.com/dillonkearns/elm-markdown/pull/154 lands in a new
elm-markdown version.
-}


wrapParenContainingDestinations : String -> String
wrapParenContainingDestinations source =
    wrapHelp 0 source


wrapHelp : Int -> String -> String
wrapHelp fromIndex source =
    case nextLinkOpen fromIndex source of
        Nothing ->
            source

        Just openAt ->
            let
                prefix : String
                prefix =
                    String.left openAt source

                afterOpen : String
                afterOpen =
                    String.dropLeft (openAt + 2) source
            in
            case parseLinkInner afterOpen of
                Nothing ->
                    wrapHelp (openAt + 1) source

                Just parsed ->
                    let
                        writtenInner : String
                        writtenInner =
                            if parsed.needsWrap then
                                parsed.leadingWhitespace
                                    ++ encodeLinkDestinationParens parsed.dest
                                    ++ String.dropLeft
                                        (String.length parsed.leadingWhitespace + String.length parsed.dest)
                                        parsed.middle

                            else
                                parsed.middle

                        rest : String
                        rest =
                            String.dropLeft (String.length parsed.middle) afterOpen

                        newSource : String
                        newSource =
                            prefix ++ "](" ++ writtenInner ++ rest
                    in
                    wrapHelp (String.length prefix + 2 + String.length writtenInner) newSource


nextLinkOpen : Int -> String -> Maybe Int
nextLinkOpen fromIndex source =
    String.indexes "](" source
        |> List.filter (\i -> i >= fromIndex)
        |> List.head


type alias ParsedInner =
    { dest : String
    , middle : String
    , leadingWhitespace : String
    , needsWrap : Bool
    }


parseLinkInner : String -> Maybe ParsedInner
parseLinkInner raw =
    let
        ( leadingWs, afterWs ) =
            splitLeadingAsciiWhitespace raw
    in
    if String.startsWith "<" (String.trimLeft afterWs) then
        parseAngleBracketInner leadingWs afterWs

    else
        parseUnbracketedInner leadingWs afterWs


parseAngleBracketInner : String -> String -> Maybe ParsedInner
parseAngleBracketInner leadingWs afterWs =
    let
        ( innerLeading, rest1 ) =
            splitLeadingAsciiWhitespace afterWs
    in
    case String.uncons rest1 of
        Nothing ->
            Nothing

        Just ( '<', afterLt ) ->
            case String.indexes ">" afterLt |> List.head of
                Nothing ->
                    Nothing

                Just j ->
                    let
                        destInner : String
                        destInner =
                            String.left j afterLt

                        afterGt : String
                        afterGt =
                            String.dropLeft (j + 1) afterLt

                        totalLeading : String
                        totalLeading =
                            leadingWs ++ innerLeading
                    in
                    case parseSuffixAfterDestination afterGt of
                        Nothing ->
                            Nothing

                        Just suffix ->
                            let
                                middle : String
                                middle =
                                    totalLeading ++ "<" ++ destInner ++ ">" ++ suffix
                            in
                            Just
                                { dest = destInner
                                , middle = middle
                                , leadingWhitespace = totalLeading
                                , needsWrap = False
                                }

        _ ->
            Nothing


parseUnbracketedInner : String -> String -> Maybe ParsedInner
parseUnbracketedInner leadingWs afterWs =
    let
        ( dest, afterDest ) =
            chompLinkDestination afterWs
    in
    if dest == "" then
        Nothing

    else
        case parseSuffixAfterDestination afterDest of
            Nothing ->
                Nothing

            Just suffix ->
                let
                    middle : String
                    middle =
                        leadingWs ++ dest ++ suffix

                    needsWrap : Bool
                    needsWrap =
                        String.any (\c -> c == '(' || c == ')') dest
                in
                Just
                    { dest = dest
                    , middle = middle
                    , leadingWhitespace = leadingWs
                    , needsWrap = needsWrap
                    }


{-| Destination for unquoted inline link: balanced `()`, no raw spaces at depth 0, `\` escapes next char.
-}
chompLinkDestination : String -> ( String, String )
chompLinkDestination input =
    chompLinkDestinationHelp input 0 ""


chompLinkDestinationHelp : String -> Int -> String -> ( String, String )
chompLinkDestinationHelp remaining depth acc =
    case String.uncons remaining of
        Nothing ->
            ( acc, "" )

        Just ( '\\', rest ) ->
            case String.uncons rest of
                Nothing ->
                    ( acc ++ "\\", "" )

                Just ( c, rest2 ) ->
                    chompLinkDestinationHelp rest2 depth (acc ++ "\\" ++ String.fromChar c)

        Just ( c, rest ) ->
            if depth == 0 && isAsciiWhitespace c then
                ( acc, remaining )

            else if depth == 0 && c == ')' then
                ( acc, remaining )

            else if c == '(' then
                chompLinkDestinationHelp rest (depth + 1) (acc ++ "(")

            else if c == ')' then
                if depth > 0 then
                    chompLinkDestinationHelp rest (depth - 1) (acc ++ ")")

                else
                    ( acc, remaining )

            else
                chompLinkDestinationHelp rest depth (acc ++ String.fromChar c)


parseSuffixAfterDestination : String -> Maybe String
parseSuffixAfterDestination afterDest =
    case parseSuffixTrimmed (String.trimLeft afterDest) of
        Nothing ->
            Nothing

        Just titled ->
            let
                gap : String
                gap =
                    String.left (String.length afterDest - String.length (String.trimLeft afterDest)) afterDest
            in
            Just (gap ++ titled)


parseSuffixTrimmed : String -> Maybe String
parseSuffixTrimmed trimmed =
    case String.uncons trimmed of
        Nothing ->
            Nothing

        Just ( ')', _ ) ->
            Just ")"

        Just ( '"', _ ) ->
            case readEscapedUntil '"' (String.dropLeft 1 trimmed) of
                Nothing ->
                    Nothing

                Just ( _, afterQuote ) ->
                    case String.uncons (String.trimLeft afterQuote) of
                        Just ( ')', tailAfter ) ->
                            Just (String.left (String.length trimmed - String.length tailAfter) trimmed)

                        _ ->
                            Nothing

        Just ( '\'', _ ) ->
            case readEscapedUntil '\'' (String.dropLeft 1 trimmed) of
                Nothing ->
                    Nothing

                Just ( _, afterQuote ) ->
                    case String.uncons (String.trimLeft afterQuote) of
                        Just ( ')', tailAfter ) ->
                            Just (String.left (String.length trimmed - String.length tailAfter) trimmed)

                        _ ->
                            Nothing

        Just ( '(', _ ) ->
            case readEscapedUntilClosingParen (String.dropLeft 1 trimmed) of
                Nothing ->
                    Nothing

                Just afterTitleParen ->
                    case String.uncons (String.trimLeft afterTitleParen) of
                        Just ( ')', tailAfter ) ->
                            Just (String.left (String.length trimmed - String.length tailAfter) trimmed)

                        _ ->
                            Nothing

        _ ->
            Nothing


readEscapedUntilClosingParen : String -> Maybe String
readEscapedUntilClosingParen remaining =
    readEscapedUntilHelpClosing remaining ""


readEscapedUntilHelpClosing : String -> String -> Maybe String
readEscapedUntilHelpClosing remaining acc =
    case String.uncons remaining of
        Nothing ->
            Nothing

        Just ( '\\', rest ) ->
            case String.uncons rest of
                Nothing ->
                    Nothing

                Just ( c, rest2 ) ->
                    readEscapedUntilHelpClosing rest2 (acc ++ "\\" ++ String.fromChar c)

        Just ( ')', rest ) ->
            Just rest

        Just ( c, rest ) ->
            readEscapedUntilHelpClosing rest (acc ++ String.fromChar c)


readEscapedUntil : Char -> String -> Maybe ( String, String )
readEscapedUntil endChar remaining =
    readEscapedUntilHelp endChar remaining ""


readEscapedUntilHelp : Char -> String -> String -> Maybe ( String, String )
readEscapedUntilHelp endChar remaining acc =
    case String.uncons remaining of
        Nothing ->
            Nothing

        Just ( '\\', rest ) ->
            case String.uncons rest of
                Nothing ->
                    Nothing

                Just ( c, rest2 ) ->
                    readEscapedUntilHelp endChar rest2 (acc ++ "\\" ++ String.fromChar c)

        Just ( c, rest ) ->
            if c == endChar then
                Just ( acc, rest )

            else
                readEscapedUntilHelp endChar rest (acc ++ String.fromChar c)


splitLeadingAsciiWhitespace : String -> ( String, String )
splitLeadingAsciiWhitespace s =
    splitLeadingAsciiWhitespaceHelp s 0


splitLeadingAsciiWhitespaceHelp : String -> Int -> ( String, String )
splitLeadingAsciiWhitespaceHelp s offset =
    case String.uncons (String.dropLeft offset s) of
        Nothing ->
            ( String.left offset s, "" )

        Just ( c, _ ) ->
            if isAsciiWhitespace c then
                splitLeadingAsciiWhitespaceHelp s (offset + 1)

            else
                ( String.left offset s, String.dropLeft offset s )


isAsciiWhitespace : Char -> Bool
isAsciiWhitespace c =
    c == ' '
        || c == '\t'
        || c == '\n'
        || c == '\r'
        || c == '\u{000C}'
        || c == '\u{000B}'


{-| Encode literal parentheses so elm-markdown inline-link regex accepts the destination.
-}
encodeLinkDestinationParens : String -> String
encodeLinkDestinationParens s =
    s
        |> String.replace "(" "%28"
        |> String.replace ")" "%29"
