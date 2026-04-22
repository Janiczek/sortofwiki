module Page exposing
    ( FrontendDetails
    , Page
    , Slug
    , frontendDetails
    , hasPublished
    , incrementPublishedRevision
    , pendingOnly
    , publishedMarkdownForLinks
    , publishedRevision
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
    , tags : List Slug
    }


type alias Slug =
    String


type alias FrontendDetails =
    { maybeMarkdownSource : Maybe String
    , backlinks : List Slug
    , tags : List Slug
    , taggedPageSlugs : List Slug
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
    , tags = []
    }


withPublishedAndPending : Slug -> String -> String -> Page
withPublishedAndPending slug publishedMarkdown_ pendingMarkdown_ =
    { slug = slug
    , publishedMarkdown = Just publishedMarkdown_
    , publishedRevision = 1
    , pendingMarkdown = Just pendingMarkdown_
    , tags = []
    }


pendingOnly : Slug -> String -> Page
pendingOnly slug pendingMarkdown_ =
    { slug = slug
    , publishedMarkdown = Nothing
    , publishedRevision = 0
    , pendingMarkdown = Just pendingMarkdown_
    , tags = []
    }


publishedRevision : Page -> Int
publishedRevision page =
    page.publishedRevision


incrementPublishedRevision : Page -> Page
incrementPublishedRevision page =
    { page | publishedRevision = page.publishedRevision + 1 }


frontendDetails : Maybe String -> List Slug -> List Slug -> List Slug -> FrontendDetails
frontendDetails maybeMarkdownSource backlinks tags taggedPageSlugs =
    { maybeMarkdownSource = maybeMarkdownSource
    , backlinks =
        backlinks
            |> Set.fromList
            |> Set.toList
    , tags =
        tags
            |> Set.fromList
            |> Set.toList
    , taggedPageSlugs =
        taggedPageSlugs
            |> Set.fromList
            |> Set.toList
    }
