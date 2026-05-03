module WikiStats exposing
    ( DailyAccumulatedSnapshot
    , FromAudit
    , FromViews
    , FromWiki
    , Summary
    , buildFromAudit
    , buildFromViews
    , buildFromWiki
    , buildFromWikiWithoutDailySnapshots
    , merge
    , withDailyAccumulatedSnapshots
    )

{-| Partitioned wiki stats cache.

Each partition is rebuilt only when its source data changes:

  - **FromWiki**: pages dict mutations (publish, approve, delete, import)
  - **FromAudit**: audit log append (recordAudit / import)
  - **FromViews**: page-view counter increments

Cached `FromWiki` from `buildFromWikiWithoutDailySnapshots` keeps `dailyAccumulatedSnapshots` empty;
`RequestWikiStats` attaches dailies via `withDailyAccumulatedSnapshots` before `merge`.

`Summary` = `merge fromWiki fromAudit fromViews` (pure, total).

-}

import Date
import Dict exposing (Dict)
import MarkdownWords
import Page
import PageLinkRefs
import Set exposing (Set)
import Submission
import Time
import Wiki
import WikiAuditLog
import WikiGraph
import WikiTodos


topN : Int
topN =
    10


{-| End-of-day totals replayed from audit (UTC day keys), one row per calendar day in chart range.
-}
type alias DailyAccumulatedSnapshot =
    { day : String
    , publishedPages : Int
    , missingPages : Int
    , todos : Int
    , publishedWords : Int
    }


{-| Stats derived purely from the wiki's pages dict (published content snapshot).

Fields owned here:

  - `publishedPageCount`
  - `missingPageCount`
  - `totalPublishedLinks`
  - `totalTags`
  - `topPagesByRevision`
  - `topPagesByInLinks` / `topPagesByOutLinks` (markdown + tags)
  - `totalPublishedWords` / `topPagesByWords` (`MarkdownWords.count` on published body)
  - `avgRevisionPerPage`

-}
type alias FromWiki =
    { publishedPageCount : Int
    , missingPageCount : Int
    , totalPublishedLinks : Int
    , totalTags : Int
    , totalPublishedWords : Int
    , topPagesByRevision : List { pageSlug : String, revision : Int }
    , topPagesByInLinks : List { pageSlug : String, inLinkCount : Int }
    , topPagesByOutLinks : List { pageSlug : String, outLinkCount : Int }
    , topPagesByWords : List { pageSlug : String, wordCount : Int }
    , avgRevisionPerPage : Float
    , dailyAccumulatedSnapshots : List DailyAccumulatedSnapshot
    }


{-| Stats derived from the wiki's audit event log.

Fields owned here:

  - `dailyActivityCounts` (UTC day buckets)
  - `topPagesByEditEvents`

-}
type alias FromAudit =
    { dailyActivityCounts : List { day : String, creates : Int, edits : Int, deletes : Int }
    , topPagesByEditEvents : List { pageSlug : String, editCount : Int }
    }


{-| Stats derived from page view counts.

Fields owned here:

  - `topPagesByViews`

-}
type alias FromViews =
    { topPagesByViews : List { pageSlug : String, viewCount : Int }
    }


{-| Fully merged stats summary sent to the frontend.

Build with `merge fromWiki fromAudit fromViews` — never construct directly.

-}
type alias Summary =
    { publishedPageCount : Int
    , missingPageCount : Int
    , totalPublishedLinks : Int
    , totalTags : Int
    , totalPublishedWords : Int
    , topPagesByRevision : List { pageSlug : String, revision : Int }
    , topPagesByInLinks : List { pageSlug : String, inLinkCount : Int }
    , topPagesByOutLinks : List { pageSlug : String, outLinkCount : Int }
    , topPagesByWords : List { pageSlug : String, wordCount : Int }
    , avgRevisionPerPage : Float
    , dailyActivityCounts : List { day : String, creates : Int, edits : Int, deletes : Int }
    , dailyWordsWritten : List { day : String, wordsChange : Int }
    , topPagesByEditEvents : List { pageSlug : String, editCount : Int }
    , topPagesByViews : List { pageSlug : String, viewCount : Int }
    , dailyAccumulatedSnapshots : List DailyAccumulatedSnapshot
    }


{-| Merge the three partitions into a `Summary`. Pure and total.
-}
merge : FromWiki -> FromAudit -> FromViews -> Summary
merge fromWiki fromAudit fromViews =
    { publishedPageCount = fromWiki.publishedPageCount
    , missingPageCount = fromWiki.missingPageCount
    , totalPublishedLinks = fromWiki.totalPublishedLinks
    , totalTags = fromWiki.totalTags
    , totalPublishedWords = fromWiki.totalPublishedWords
    , topPagesByRevision = fromWiki.topPagesByRevision
    , topPagesByInLinks = fromWiki.topPagesByInLinks
    , topPagesByOutLinks = fromWiki.topPagesByOutLinks
    , topPagesByWords = fromWiki.topPagesByWords
    , avgRevisionPerPage = fromWiki.avgRevisionPerPage
    , dailyActivityCounts = fromAudit.dailyActivityCounts
    , dailyWordsWritten = dailyWordsWrittenFromSnapshots fromWiki.dailyAccumulatedSnapshots
    , topPagesByEditEvents = fromAudit.topPagesByEditEvents
    , topPagesByViews = fromViews.topPagesByViews
    , dailyAccumulatedSnapshots = fromWiki.dailyAccumulatedSnapshots
    }


{-| Per UTC day: end-of-day total published word count minus previous end-of-day total (first day vs zero).
-}
dailyWordsWrittenFromSnapshots : List DailyAccumulatedSnapshot -> List { day : String, wordsChange : Int }
dailyWordsWrittenFromSnapshots snaps =
    let
        step :
            DailyAccumulatedSnapshot
            -> ( Int, List { day : String, wordsChange : Int } )
            -> ( Int, List { day : String, wordsChange : Int } )
        step snap ( prevTotal, acc ) =
            ( snap.publishedWords
            , { day = snap.day, wordsChange = snap.publishedWords - prevTotal } :: acc
            )
    in
    snaps
        |> List.foldl step ( 0, [] )
        |> Tuple.second
        |> List.reverse


{-| Same field math as `buildFromWiki` but skips `dailyAccumulatedSnapshots` (empty list).

Backend caches this shape; expensive replay runs in `withDailyAccumulatedSnapshots` on stats read.

`submissions`, `auditEvents`, and `asOf` are unused — same arity as `buildFromWiki` for call-site uniformity.

-}
buildFromWikiWithoutDailySnapshots : Wiki.Slug -> Wiki.Wiki -> FromWiki
buildFromWikiWithoutDailySnapshots wikiSlug wiki =
    buildFromWikiCurrentSnapshot wikiSlug wiki


{-| Fill `dailyAccumulatedSnapshots` from audit replay (JIT for stats responses).
-}
withDailyAccumulatedSnapshots :
    Wiki.Slug
    -> Dict String Submission.Submission
    -> List WikiAuditLog.AuditEvent
    -> Time.Posix
    -> FromWiki
    -> FromWiki
withDailyAccumulatedSnapshots wikiSlug submissions auditEvents asOf fromWiki =
    { fromWiki
        | dailyAccumulatedSnapshots =
            buildDailyAccumulatedSnapshots wikiSlug submissions auditEvents asOf
    }


{-| Build `FromWiki` from the current wiki snapshot.

`submissions` + `auditEvents` are used only for `dailyAccumulatedSnapshots` (replay).

`asOf` is server UTC “today” for chart ranges (inclusive end day).

-}
buildFromWiki : Wiki.Slug -> Wiki.Wiki -> Dict String Submission.Submission -> List WikiAuditLog.AuditEvent -> Time.Posix -> FromWiki
buildFromWiki wikiSlug wiki submissions auditEvents asOf =
    buildFromWikiWithoutDailySnapshots wikiSlug wiki
        |> withDailyAccumulatedSnapshots wikiSlug submissions auditEvents asOf


buildFromWikiCurrentSnapshot : Wiki.Slug -> Wiki.Wiki -> FromWiki
buildFromWikiCurrentSnapshot wikiSlug wiki =
    let
        publishedPairs : List ( Page.Slug, Page.Page )
        publishedPairs =
            wiki.pages
                |> Dict.toList
                |> List.filter (\( _, page ) -> Page.hasPublished page)

        publishedSlugSet : Set String
        publishedSlugSet =
            publishedPairs
                |> List.map (Tuple.first >> String.toLower)
                |> Set.fromList

        publishedMarkdownSources : Dict Page.Slug String
        publishedMarkdownSources =
            publishedPairs
                |> List.map
                    (\( slug, page ) ->
                        ( slug, Page.publishedMarkdownForLinks page )
                    )
                |> Dict.fromList

        publishedPageTags : Dict Page.Slug (List Page.Slug)
        publishedPageTags =
            publishedPairs
                |> List.map (\( slug, page ) -> ( slug, page.tags ))
                |> Dict.fromList

        totalPublishedLinks : Int
        totalPublishedLinks =
            publishedMarkdownSources
                |> Dict.values
                |> List.concatMap (PageLinkRefs.linkedPageSlugs wikiSlug)
                |> List.length

        totalTags : Int
        totalTags =
            publishedPageTags
                |> Dict.values
                |> List.concat
                |> List.length

        missingPageSlugs : List Page.Slug
        missingPageSlugs =
            publishedMarkdownSources
                |> Dict.values
                |> List.concatMap (PageLinkRefs.linkedPageSlugs wikiSlug)
                |> List.filter (\slug -> not (Set.member (String.toLower slug) publishedSlugSet))
                |> List.foldl
                    (\slug acc ->
                        if Set.member (String.toLower slug) acc then
                            acc

                        else
                            Set.insert (String.toLower slug) acc
                    )
                    Set.empty
                |> Set.toList

        topPagesByRevision : List { pageSlug : String, revision : Int }
        topPagesByRevision =
            publishedPairs
                |> List.map
                    (\( slug, page ) ->
                        { pageSlug = slug, revision = Page.publishedRevision page }
                    )
                |> List.sortBy (\r -> negate r.revision)
                |> List.take topN

        directedLinkCounts : { inByNormalizedTarget : Dict String Int, outByNormalizedSource : Dict String Int }
        directedLinkCounts =
            WikiGraph.directedInOutCountsBySlug wikiSlug publishedMarkdownSources publishedPageTags

        topPagesByInLinks : List { pageSlug : String, inLinkCount : Int }
        topPagesByInLinks =
            publishedPairs
                |> List.map Tuple.first
                |> List.map
                    (\slug ->
                        { pageSlug = slug
                        , inLinkCount =
                            Dict.get (String.toLower slug) directedLinkCounts.inByNormalizedTarget
                                |> Maybe.withDefault 0
                        }
                    )
                |> List.sortBy (\r -> negate r.inLinkCount)
                |> List.take topN

        topPagesByOutLinks : List { pageSlug : String, outLinkCount : Int }
        topPagesByOutLinks =
            publishedPairs
                |> List.map Tuple.first
                |> List.map
                    (\slug ->
                        { pageSlug = slug
                        , outLinkCount =
                            Dict.get (String.toLower slug) directedLinkCounts.outByNormalizedSource
                                |> Maybe.withDefault 0
                        }
                    )
                |> List.sortBy (\r -> negate r.outLinkCount)
                |> List.take topN

        topPagesByWords : List { pageSlug : String, wordCount : Int }
        topPagesByWords =
            publishedPairs
                |> List.map
                    (\( slug, page ) ->
                        { pageSlug = slug
                        , wordCount =
                            page
                                |> Page.publishedMarkdownForLinks
                                |> MarkdownWords.count
                        }
                    )
                |> List.sortBy (\r -> negate r.wordCount)
                |> List.take topN

        totalPublishedWords : Int
        totalPublishedWords =
            publishedPairs
                |> List.map (Tuple.second >> Page.publishedMarkdownForLinks >> MarkdownWords.count)
                |> List.sum

        publishedPageCount : Int
        publishedPageCount =
            List.length publishedPairs

        avgRevisionPerPage : Float
        avgRevisionPerPage =
            if publishedPageCount == 0 then
                0.0

            else
                let
                    totalRevisions : Int
                    totalRevisions =
                        publishedPairs
                            |> List.map (Tuple.second >> Page.publishedRevision)
                            |> List.sum
                in
                toFloat totalRevisions / toFloat publishedPageCount
    in
    { publishedPageCount = publishedPageCount
    , missingPageCount = List.length missingPageSlugs
    , totalPublishedLinks = totalPublishedLinks
    , totalTags = totalTags
    , totalPublishedWords = totalPublishedWords
    , topPagesByRevision = topPagesByRevision
    , topPagesByInLinks = topPagesByInLinks
    , topPagesByOutLinks = topPagesByOutLinks
    , topPagesByWords = topPagesByWords
    , avgRevisionPerPage = avgRevisionPerPage
    , dailyAccumulatedSnapshots = []
    }


sortAuditEventsByTime : List WikiAuditLog.AuditEvent -> List WikiAuditLog.AuditEvent
sortAuditEventsByTime events =
    events
        |> List.sortBy (\e -> Time.posixToMillis e.at)


uniqueSortedEventDays : List WikiAuditLog.AuditEvent -> List String
uniqueSortedEventDays events =
    events
        |> List.foldl
            (\e acc ->
                let
                    d : String
                    d =
                        posixToUtcDayString e.at
                in
                Dict.insert d () acc
            )
            Dict.empty
        |> Dict.keys
        |> List.sort


{-| UTC calendar days from first audit event day through `asOf` day (inclusive), ascending.

Empty when there are no audit events.

-}
utcChartDaysAscending : Time.Posix -> List WikiAuditLog.AuditEvent -> List String
utcChartDaysAscending asOf events =
    case uniqueSortedEventDays events |> List.head of
        Nothing ->
            []

        Just firstDayStr ->
            let
                lastDayStr : String
                lastDayStr =
                    posixToUtcDayString asOf
            in
            case ( Date.fromIsoString firstDayStr, Date.fromIsoString lastDayStr ) of
                ( Ok firstDate, Ok lastDate ) ->
                    case Date.compare firstDate lastDate of
                        GT ->
                            []

                        _ ->
                            Date.range Date.Day 1 firstDate (Date.add Date.Days 1 lastDate)
                                |> List.map Date.toIsoString

                _ ->
                    []


submissionByIdString : Dict String Submission.Submission -> String -> Maybe Submission.Submission
submissionByIdString submissions submissionId =
    Dict.get submissionId submissions


applyAuditEventToWiki : Wiki.Slug -> Dict String Submission.Submission -> Wiki.Wiki -> WikiAuditLog.AuditEvent -> Wiki.Wiki
applyAuditEventToWiki wikiSlug submissions wiki event =
    case event.kind of
        WikiAuditLog.TrustedPublishedNewPage body ->
            Wiki.publishNewPageOnWiki
                { pageSlug = body.pageSlug
                , markdown = body.markdown
                , tags = []
                }
                wiki

        WikiAuditLog.TrustedPublishedPageEdit body ->
            case Dict.get body.pageSlug wiki.pages of
                Nothing ->
                    wiki

                Just page ->
                    Wiki.applyPublishedMarkdownEdit body.pageSlug body.afterMarkdown page.tags wiki

        WikiAuditLog.TrustedPublishedPageDelete body ->
            Wiki.removePublishedPage body.pageSlug wiki

        WikiAuditLog.ApprovedPublishedNewPage body ->
            case submissionByIdString submissions body.submissionId of
                Nothing ->
                    wiki

                Just sub ->
                    if sub.wikiSlug /= wikiSlug then
                        wiki

                    else
                        case sub.kind of
                            Submission.NewPage newBody ->
                                Wiki.publishNewPageOnWiki newBody wiki

                            Submission.EditPage _ ->
                                wiki

                            Submission.DeletePage _ ->
                                wiki

        WikiAuditLog.ApprovedPublishedPageEdit body ->
            case submissionByIdString submissions body.submissionId of
                Nothing ->
                    wiki

                Just sub ->
                    if sub.wikiSlug /= wikiSlug then
                        wiki

                    else
                        case sub.kind of
                            Submission.EditPage editBody ->
                                Wiki.applyPublishedMarkdownEdit editBody.pageSlug editBody.proposedMarkdown editBody.tags wiki

                            Submission.NewPage _ ->
                                wiki

                            Submission.DeletePage _ ->
                                wiki

        WikiAuditLog.ApprovedPublishedPageDelete body ->
            case submissionByIdString submissions body.submissionId of
                Nothing ->
                    wiki

                Just sub ->
                    if sub.wikiSlug /= wikiSlug then
                        wiki

                    else
                        case sub.kind of
                            Submission.DeletePage delBody ->
                                Wiki.removePublishedPage delBody.pageSlug wiki

                            Submission.NewPage _ ->
                                wiki

                            Submission.EditPage _ ->
                                wiki

        WikiAuditLog.ApprovedSubmission _ ->
            wiki

        WikiAuditLog.RejectedSubmission _ ->
            wiki

        WikiAuditLog.RequestedSubmissionChanges _ ->
            wiki

        WikiAuditLog.PromotedContributorToTrusted _ ->
            wiki

        WikiAuditLog.DemotedTrustedToContributor _ ->
            wiki

        WikiAuditLog.GrantedWikiAdmin _ ->
            wiki

        WikiAuditLog.RevokedWikiAdmin _ ->
            wiki


wikiTotalsSnapshot : Wiki.Slug -> Wiki.Wiki -> DailyAccumulatedSnapshot
wikiTotalsSnapshot wikiSlug wiki =
    let
        sources : Dict Page.Slug String
        sources =
            Wiki.frontendDetails wiki
                |> (\details -> details.publishedPageMarkdownSources)

        publishedPages : Int
        publishedPages =
            wiki.pages
                |> Dict.toList
                |> List.filter (\( _, page ) -> Page.hasPublished page)
                |> List.length

        todoSummary : WikiTodos.Summary
        todoSummary =
            WikiTodos.summary wikiSlug sources

        missingPages : Int
        missingPages =
            List.length todoSummary.missingPages

        todos : Int
        todos =
            List.length todoSummary.todos

        publishedWords : Int
        publishedWords =
            sources
                |> Dict.values
                |> List.map MarkdownWords.count
                |> List.sum
    in
    { day = ""
    , publishedPages = publishedPages
    , missingPages = missingPages
    , todos = todos
    , publishedWords = publishedWords
    }


replayWikiThroughDayInclusive : Wiki.Slug -> Dict String Submission.Submission -> List WikiAuditLog.AuditEvent -> String -> Wiki.Wiki
replayWikiThroughDayInclusive wikiSlug submissions sortedEvents endDayInclusive =
    sortedEvents
        |> List.filter (\e -> posixToUtcDayString e.at <= endDayInclusive)
        |> List.foldl
            (\event w -> applyAuditEventToWiki wikiSlug submissions w event)
            (Wiki.wikiWithPages wikiSlug "" Dict.empty)


snapshotAtEndOfDay : Wiki.Slug -> Dict String Submission.Submission -> List WikiAuditLog.AuditEvent -> String -> DailyAccumulatedSnapshot
snapshotAtEndOfDay wikiSlug submissions sortedEvents day =
    let
        w : Wiki.Wiki
        w =
            replayWikiThroughDayInclusive wikiSlug submissions sortedEvents day

        snap : DailyAccumulatedSnapshot
        snap =
            wikiTotalsSnapshot wikiSlug w
    in
    { snap | day = day }


buildDailyAccumulatedSnapshots : Wiki.Slug -> Dict String Submission.Submission -> List WikiAuditLog.AuditEvent -> Time.Posix -> List DailyAccumulatedSnapshot
buildDailyAccumulatedSnapshots wikiSlug submissions auditEvents asOf =
    let
        sorted : List WikiAuditLog.AuditEvent
        sorted =
            sortAuditEventsByTime auditEvents

        days : List String
        days =
            utcChartDaysAscending asOf auditEvents
    in
    days
        |> List.map (snapshotAtEndOfDay wikiSlug submissions sorted)


{-| Build `FromAudit` from a wiki's raw audit event list.

Pure; no I/O. Day keys are UTC `YYYY-MM-DD` strings derived from event timestamps.

`dailyActivityCounts` lists every UTC day from the first audit day through `asOf` (inclusive),
with zeros on quiet days.

Only page-content events count (creates, edits, deletes via both trusted-publish and
approved-submission paths); moderation events (promote, reject, etc.) are excluded.

-}
buildFromAudit : Time.Posix -> List WikiAuditLog.AuditEvent -> FromAudit
buildFromAudit asOf events =
    let
        isEditForPage : WikiAuditLog.AuditEventKind -> Maybe String
        isEditForPage kind =
            case kind of
                WikiAuditLog.TrustedPublishedPageEdit { pageSlug } ->
                    Just pageSlug

                WikiAuditLog.ApprovedPublishedPageEdit { pageSlug } ->
                    Just pageSlug

                WikiAuditLog.ApprovedSubmission _ ->
                    Nothing

                WikiAuditLog.RejectedSubmission _ ->
                    Nothing

                WikiAuditLog.RequestedSubmissionChanges _ ->
                    Nothing

                WikiAuditLog.PromotedContributorToTrusted _ ->
                    Nothing

                WikiAuditLog.DemotedTrustedToContributor _ ->
                    Nothing

                WikiAuditLog.GrantedWikiAdmin _ ->
                    Nothing

                WikiAuditLog.RevokedWikiAdmin _ ->
                    Nothing

                WikiAuditLog.TrustedPublishedNewPage _ ->
                    Nothing

                WikiAuditLog.TrustedPublishedPageDelete _ ->
                    Nothing

                WikiAuditLog.ApprovedPublishedNewPage _ ->
                    Nothing

                WikiAuditLog.ApprovedPublishedPageDelete _ ->
                    Nothing

        editPageSlugs : List String
        editPageSlugs =
            events
                |> List.filterMap (\e -> isEditForPage e.kind)

        topPagesByEditEvents : List { pageSlug : String, editCount : Int }
        topPagesByEditEvents =
            editPageSlugs
                |> List.foldl
                    (\slug acc ->
                        Dict.update slug
                            (\mv -> Just (Maybe.withDefault 0 mv + 1))
                            acc
                    )
                    Dict.empty
                |> Dict.toList
                |> List.map (\( slug, count ) -> { pageSlug = slug, editCount = count })
                |> List.sortBy (\r -> negate r.editCount)
                |> List.take topN

        classifyKind : WikiAuditLog.AuditEventKind -> Maybe ActivityClass
        classifyKind kind =
            case kind of
                WikiAuditLog.TrustedPublishedNewPage _ ->
                    Just ActivityCreate

                WikiAuditLog.ApprovedPublishedNewPage _ ->
                    Just ActivityCreate

                WikiAuditLog.TrustedPublishedPageEdit _ ->
                    Just ActivityEdit

                WikiAuditLog.ApprovedPublishedPageEdit _ ->
                    Just ActivityEdit

                WikiAuditLog.TrustedPublishedPageDelete _ ->
                    Just ActivityDelete

                WikiAuditLog.ApprovedPublishedPageDelete _ ->
                    Just ActivityDelete

                WikiAuditLog.ApprovedSubmission _ ->
                    Nothing

                WikiAuditLog.RejectedSubmission _ ->
                    Nothing

                WikiAuditLog.RequestedSubmissionChanges _ ->
                    Nothing

                WikiAuditLog.PromotedContributorToTrusted _ ->
                    Nothing

                WikiAuditLog.DemotedTrustedToContributor _ ->
                    Nothing

                WikiAuditLog.GrantedWikiAdmin _ ->
                    Nothing

                WikiAuditLog.RevokedWikiAdmin _ ->
                    Nothing

        activityByDay : Dict String { creates : Int, edits : Int, deletes : Int }
        activityByDay =
            events
                |> List.foldl
                    (\event acc ->
                        case classifyKind event.kind of
                            Nothing ->
                                acc

                            Just cls ->
                                let
                                    day : String
                                    day =
                                        posixToUtcDayString event.at
                                in
                                Dict.update day
                                    (\mv ->
                                        let
                                            current : { creates : Int, edits : Int, deletes : Int }
                                            current =
                                                Maybe.withDefault { creates = 0, edits = 0, deletes = 0 } mv
                                        in
                                        Just
                                            (case cls of
                                                ActivityCreate ->
                                                    { current | creates = current.creates + 1 }

                                                ActivityEdit ->
                                                    { current | edits = current.edits + 1 }

                                                ActivityDelete ->
                                                    { current | deletes = current.deletes + 1 }
                                            )
                                    )
                                    acc
                    )
                    Dict.empty

        dailyActivityCounts : List { day : String, creates : Int, edits : Int, deletes : Int }
        dailyActivityCounts =
            utcChartDaysAscending asOf events
                |> List.map
                    (\day ->
                        Dict.get day activityByDay
                            |> Maybe.withDefault { creates = 0, edits = 0, deletes = 0 }
                            |> (\counts -> { day = day, creates = counts.creates, edits = counts.edits, deletes = counts.deletes })
                    )
    in
    { dailyActivityCounts = dailyActivityCounts
    , topPagesByEditEvents = topPagesByEditEvents
    }


{-| Build `FromViews` from the view-count dict for one wiki (page slug → view count).
-}
buildFromViews : Dict Page.Slug Int -> FromViews
buildFromViews viewCounts =
    let
        topPagesByViews : List { pageSlug : String, viewCount : Int }
        topPagesByViews =
            viewCounts
                |> Dict.toList
                |> List.map (\( slug, count ) -> { pageSlug = slug, viewCount = count })
                |> List.sortBy (\r -> negate r.viewCount)
                |> List.take topN
    in
    { topPagesByViews = topPagesByViews }


type ActivityClass
    = ActivityCreate
    | ActivityEdit
    | ActivityDelete


posixToUtcDayString : Time.Posix -> String
posixToUtcDayString posix =
    let
        zone : Time.Zone
        zone =
            Time.utc

        pad2 : Int -> String
        pad2 n =
            n
                |> String.fromInt
                |> String.padLeft 2 '0'

        year : String
        year =
            Time.toYear zone posix
                |> String.fromInt
                |> String.padLeft 4 '0'

        month : String
        month =
            pad2 (monthToInt (Time.toMonth zone posix))

        day : String
        day =
            pad2 (Time.toDay zone posix)
    in
    year ++ "-" ++ month ++ "-" ++ day


monthToInt : Time.Month -> Int
monthToInt month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12
