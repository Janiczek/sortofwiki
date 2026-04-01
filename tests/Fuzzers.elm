module Fuzzers exposing
    ( pageSlug
    , wikiSlug
    , wikiSummary
    )

import Fuzz exposing (Fuzzer)
import Page
import Wiki


wikiSummary : Fuzzer Wiki.Summary
wikiSummary =
    Fuzz.map2 Wiki.Summary
        wikiSlug
        wikiName


wikiSlug : Fuzzer Wiki.Slug
wikiSlug =
    nonEmptyString


pageSlug : Fuzzer Page.Slug
pageSlug =
    nonEmptyString


wikiName : Fuzzer String
wikiName =
    nonEmptyString


nonEmptyString : Fuzzer String
nonEmptyString =
    Fuzz.string
        |> Fuzz.map (\s -> "x" ++ s)
