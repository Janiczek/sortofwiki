module Chapters.ResultNotice exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import UI.ResultNotice


chapter_ : Chapter x
chapter_ =
    chapter "UI.ResultNotice"
        |> renderComponentList
            [ ( "ResultNotice.fromMaybeResult - Nothing"
              , UI.ResultNotice.fromMaybeResult
                    { id = "book-result-a"
                    , okText = "Done."
                    , errToText = identity
                    }
                    Nothing
              )
            , ( "ResultNotice.fromMaybeResult - Ok"
              , UI.ResultNotice.fromMaybeResult
                    { id = "book-result-b"
                    , okText = "Signed in."
                    , errToText = identity
                    }
                    (Just (Ok ()))
              )
            , ( "ResultNotice.fromMaybeResult - Err"
              , UI.ResultNotice.fromMaybeResult
                    { id = "book-result-c"
                    , okText = "Done."
                    , errToText = identity
                    }
                    (Just (Err "Invalid password."))
              )
            ]
