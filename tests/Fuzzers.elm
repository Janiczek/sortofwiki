module Fuzzers exposing
    ( wikiSlug
    , wikiSummary
    )

import Fuzz exposing (Fuzzer)
import Wiki


wikiSummary : Fuzzer Wiki.Summary
wikiSummary =
    Fuzz.map2 Wiki.Summary
        wikiSlug
        wikiName


wikiSlug : Fuzzer Wiki.Slug
wikiSlug =
    nonEmptyString


wikiName : Fuzzer String
wikiName =
    nonEmptyString


nonEmptyString : Fuzzer String
nonEmptyString =
    Fuzz.string
        |> Fuzz.map (\s -> "x" ++ s)
