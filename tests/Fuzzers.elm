module Fuzzers exposing (wikiSummary)

import Fuzz
import WikiSummary


wikiSummary : Fuzz.Fuzzer WikiSummary.WikiSummary
wikiSummary =
    Fuzz.map2 WikiSummary.WikiSummary
        nonEmptyString
        nonEmptyString


nonEmptyString : Fuzz.Fuzzer String
nonEmptyString =
    Fuzz.string
        |> Fuzz.map (\s -> "x" ++ s)
