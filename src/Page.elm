module Page exposing
    ( FrontendDetails
    , Page
    , Slug
    , frontendDetails
    , hasPublished
    , incrementPublishedRevision
    , pendingOnly
    , publishedMarkdownForLinks
    , publishedPageTitle
    , publishedRevision
    , titleHintFromMarkdown
    , withPublished
    , withPublishedAndPending
    )

import Set


{-| Wiki page: optional published revision (what viewers see) and optional pending draft
(never sent on public read paths until a later publish flow exists).
-}
type alias Page =
    { slug : Slug
    , publishedMarkdown : Maybe String
    , publishedRevision : Int
    , pendingMarkdown : Maybe String
    }


type alias Slug =
    String


type alias FrontendDetails =
    { markdownSource : String
    , backlinks : List Slug
    }


hasPublished : Page -> Bool
hasPublished page =
    case page.publishedMarkdown of
        Nothing ->
            False

        Just _ ->
            True


{-| Markdown used for link/backlink extraction; pending text is ignored.
-}
publishedMarkdownForLinks : Page -> String
publishedMarkdownForLinks page =
    case page.publishedMarkdown of
        Nothing ->
            ""

        Just markdown ->
            markdown


withPublished : Slug -> String -> Page
withPublished slug markdown =
    { slug = slug
    , publishedMarkdown = Just markdown
    , publishedRevision = 1
    , pendingMarkdown = Nothing
    }


withPublishedAndPending : Slug -> String -> String -> Page
withPublishedAndPending slug publishedMarkdown_ pendingMarkdown_ =
    { slug = slug
    , publishedMarkdown = Just publishedMarkdown_
    , publishedRevision = 1
    , pendingMarkdown = Just pendingMarkdown_
    }


pendingOnly : Slug -> String -> Page
pendingOnly slug pendingMarkdown_ =
    { slug = slug
    , publishedMarkdown = Nothing
    , publishedRevision = 0
    , pendingMarkdown = Just pendingMarkdown_
    }


publishedRevision : Page -> Int
publishedRevision page =
    page.publishedRevision


incrementPublishedRevision : Page -> Page
incrementPublishedRevision page =
    { page | publishedRevision = page.publishedRevision + 1 }


frontendDetails : String -> List Slug -> FrontendDetails
frontendDetails markdownSource backlinks =
    { markdownSource = markdownSource
    , backlinks =
        backlinks
            |> Set.fromList
            |> Set.toList
    }


{-| If the source begins with an ATX H1 line (`# Title`), returns the title text.
Used for page chrome when the published body repeats the same heading.
-}
titleHintFromMarkdown : String -> Maybe String
titleHintFromMarkdown raw =
    raw
        |> String.trim
        |> String.lines
        |> List.head
        |> Maybe.andThen parseAtxH1Line


parseAtxH1Line : String -> Maybe String
parseAtxH1Line line =
    let
        trimmed : String
        trimmed =
            String.trim line
    in
    if String.startsWith "#" trimmed then
        trimmed
            |> String.dropLeft 1
            |> String.trim
            |> stripClosingAtxHashes
            |> (\t ->
                    if String.isEmpty t then
                        Nothing

                    else
                        Just t
               )

    else
        Nothing


stripClosingAtxHashes : String -> String
stripClosingAtxHashes s0 =
    let
        s : String
        s =
            String.trimRight s0
    in
    if String.endsWith "#" s && s /= "#" then
        s
            |> String.dropRight 1
            |> String.trimRight
            |> stripClosingAtxHashes

    else
        s


{-| Display title for a published page: first markdown H1 if present, else the page slug.
-}
publishedPageTitle : Slug -> FrontendDetails -> String
publishedPageTitle slug details =
    titleHintFromMarkdown details.markdownSource
        |> Maybe.withDefault slug
