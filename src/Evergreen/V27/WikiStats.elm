module Evergreen.V27.WikiStats exposing (..)


type alias DailyAccumulatedSnapshot =
    { day : String
    , publishedPages : Int
    , missingPages : Int
    , todos : Int
    }


type alias Summary =
    { publishedPageCount : Int
    , missingPageCount : Int
    , totalPublishedLinks : Int
    , totalTags : Int
    , topPagesByRevision :
        List
            { pageSlug : String
            , revision : Int
            }
    , topPagesByInLinks :
        List
            { pageSlug : String
            , inLinkCount : Int
            }
    , topPagesByOutLinks :
        List
            { pageSlug : String
            , outLinkCount : Int
            }
    , avgRevisionPerPage : Float
    , dailyActivityCounts :
        List
            { day : String
            , creates : Int
            , edits : Int
            , deletes : Int
            }
    , topPagesByEditEvents :
        List
            { pageSlug : String
            , editCount : Int
            }
    , topPagesByViews :
        List
            { pageSlug : String
            , viewCount : Int
            }
    , dailyAccumulatedSnapshots : List DailyAccumulatedSnapshot
    }


type alias FromWiki =
    { publishedPageCount : Int
    , missingPageCount : Int
    , totalPublishedLinks : Int
    , totalTags : Int
    , topPagesByRevision :
        List
            { pageSlug : String
            , revision : Int
            }
    , topPagesByInLinks :
        List
            { pageSlug : String
            , inLinkCount : Int
            }
    , topPagesByOutLinks :
        List
            { pageSlug : String
            , outLinkCount : Int
            }
    , avgRevisionPerPage : Float
    , dailyAccumulatedSnapshots : List DailyAccumulatedSnapshot
    }


type alias FromAudit =
    { dailyActivityCounts :
        List
            { day : String
            , creates : Int
            , edits : Int
            , deletes : Int
            }
    , topPagesByEditEvents :
        List
            { pageSlug : String
            , editCount : Int
            }
    }


type alias FromViews =
    { topPagesByViews :
        List
            { pageSlug : String
            , viewCount : Int
            }
    }
