module Page exposing
    ( FrontendDetails
    , Page
    , Slug
    , frontendDetails
    , hasPublished
    , pendingOnly
    , publishedMarkdownForLinks
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
    , pendingMarkdown = Nothing
    }


withPublishedAndPending : Slug -> String -> String -> Page
withPublishedAndPending slug publishedMarkdown_ pendingMarkdown_ =
    { slug = slug
    , publishedMarkdown = Just publishedMarkdown_
    , pendingMarkdown = Just pendingMarkdown_
    }


pendingOnly : Slug -> String -> Page
pendingOnly slug pendingMarkdown_ =
    { slug = slug
    , publishedMarkdown = Nothing
    , pendingMarkdown = Just pendingMarkdown_
    }


frontendDetails : String -> List Slug -> FrontendDetails
frontendDetails markdownSource backlinks =
    { markdownSource = markdownSource
    , backlinks =
        backlinks
            |> Set.fromList
            |> Set.toList
    }
