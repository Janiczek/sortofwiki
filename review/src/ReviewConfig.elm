module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import Docs.ReviewAtDocs
import NoConfusingPrefixOperator
import NoDebug.Log
import NoDebug.TodoOrToString
import NoExposingEverything
import NoImportingEverything
import NoMissingTypeAnnotation
import NoMissingTypeAnnotationInLetIn
import NoMissingTypeExpose
import NoPrematureLetComputation
import NoSimpleLetBody
import NoTestValuesInProductionCode
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import Review.Rule as Rule exposing (Rule)
import Simplify


config : List Rule
config =
    [ Docs.ReviewAtDocs.rule
    , NoConfusingPrefixOperator.rule
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
        |> Rule.ignoreErrorsForDirectories [ "tests/" ]
    , NoExposingEverything.rule
        |> Rule.ignoreErrorsForDirectories [ "src/Evergreen/" ]
    , NoImportingEverything.rule []
        |> Rule.ignoreErrorsForDirectories [ "src/Evergreen/" ]
    , NoMissingTypeAnnotation.rule
    , NoMissingTypeAnnotationInLetIn.rule
    , NoMissingTypeExpose.rule
    , NoSimpleLetBody.rule
    , NoPrematureLetComputation.rule
    , NoUnused.CustomTypeConstructors.rule []
        |> Rule.ignoreErrorsForFiles
            [ "src/Types.elm"
            , "src/Backend.elm"
            ]
        |> Rule.ignoreErrorsForDirectories [ "src/Evergreen/" ]
    , NoUnused.CustomTypeConstructorArgs.rule
        |> Rule.ignoreErrorsForDirectories [ "src/Evergreen/" ]
        |> Rule.ignoreErrorsForFiles
            [ "src/WikiRole.elm" -- type mustn't be opaque
            ]
    , NoUnused.Exports.rule
        |> Rule.ignoreErrorsForFiles
            [ "src/Env.elm"
            , "src/Store.elm"
            , "src/WikiRole.elm" -- type mustn't be opaque
            ]
        |> Rule.ignoreErrorsForDirectories [ "src/Evergreen/" ]
    , NoUnused.Parameters.rule
        |> Rule.ignoreErrorsForDirectories [ "src/Evergreen/" ]
    , NoUnused.Patterns.rule
    , NoUnused.Variables.rule
        |> Rule.ignoreErrorsForDirectories [ "src/Evergreen/" ]
    , Simplify.rule Simplify.defaults
        |> Rule.ignoreErrorsForDirectories [ "src/Evergreen/" ]
    , NoTestValuesInProductionCode.rule
        (NoTestValuesInProductionCode.startsWith "test_")
    ]
