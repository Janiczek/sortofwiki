module UI.ZIndex exposing (ZIndexUsecase(..), class)

import SeqDict exposing (SeqDict)


type ZIndexUsecase
    = AuditTableHeader
    | WikiGraphMinimap
    | HeaderSearchLayer
    | HeaderSearchPopup


{-| Top: smaller z-index, bottom: larger z-index.
-}
orderedUsecases : List ZIndexUsecase
orderedUsecases =
    [ HeaderSearchLayer
    , AuditTableHeader
    , WikiGraphMinimap
    , HeaderSearchPopup
    ]


valuesByUsecase : SeqDict ZIndexUsecase Int
valuesByUsecase =
    orderedUsecases
        |> List.indexedMap
            (\index usecase ->
                ( usecase, index + 1 )
            )
        |> SeqDict.fromList


value : ZIndexUsecase -> Int
value usecase =
    SeqDict.get usecase valuesByUsecase
        |> Maybe.withDefault 0


class : ZIndexUsecase -> String
class usecase =
    "z-[" ++ String.fromInt (value usecase) ++ "]"
