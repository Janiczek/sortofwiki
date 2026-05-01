module ProgramTest.Fixtures exposing
    ( demoAboutPublished
    , demoGuidesPublished
    , demoHomePublished
    , demoKitchenSinkMarkdownPublished
    , demoMarkdownPlaygroundPublished
    )


demoHomePublished : String
demoHomePublished =
    """Welcome to the Demo Wiki. See [Guides](/w/Demo/p/Guides) and [MarkdownPlayground](/w/Demo/p/MarkdownPlayground)."""


demoGuidesPublished : String
demoGuidesPublished =
    """## How to use this wiki

Read the **manual**.

The home page links here, so it shows under *Backlinks* below. That list is inbound links only—this page does not link back to home.
"""


demoAboutPublished : String
demoAboutPublished =
    """This page links only to [[Home]]. {TODO: explain contributor roles}. Missing topic: [[TodoGap]]. The home page does not link here; *Backlinks* on home still lists this page because other pages pointing **to** the current page are what backlinks mean.
"""


demoMarkdownPlaygroundPublished : String
demoMarkdownPlaygroundPublished =
    """# Markdown Playground

This page demonstrates seeded Markdown support.

## Inline formatting

This paragraph includes **bold**, *italic*, `inline code`, and ~~strikethrough~~.

## Links

- External link: [Lamdera](https://lamdera.com)
- In-wiki link by slug: [[Guides]]
- In-wiki link with label: [[About|About this wiki]]
- Missing page (red link in UI): [[Story49MissingPage]]
- Missing page with diacritics: [[Návsí]]
- TODO marker: {TODO: add contributor examples}
- Shared missing page: [[TodoGap]]
- Raw URL autolink: <https://example.com>

## Lists

- Unordered item one
- Unordered item two
  - Nested unordered item

1. Ordered item one
2. Ordered item two

## Blockquote

> This is a blockquote.
>
> It spans multiple lines.

## Code block

```elm
viewGreeting : String -> String
viewGreeting name =
    "Hello, " ++ name
```

## Horizontal rule

---

## Escaping and entities

Use \\*asterisks\\* literally and show an ampersand entity: &amp;.
"""


{-| Published page for program-test Story 55: `$$` → `inline-equation`, `$$$` → `block-equation`, plus every Markdown shape the parser + `PageMarkdown` renderer support.
-}
demoKitchenSinkMarkdownPublished : String
demoKitchenSinkMarkdownPublished =
    """# Kitchen sink

Seeded Markdown: headings, inline styles, links, lists, block quote, fenced code, rule, table, tasks, wiki links, autolink, math delimiters, escapes.

## Math (custom elements)

Inline equation $$progtestStory55Inline$$ in a sentence.

$$$progtestStory55Block$$$

## Headings

### Third level

#### Fourth level

##### Fifth level

###### Sixth level

## Inline formatting

**Bold**, *italic*, `inline code`, and ~~strikethrough~~.

## Links

- [External link](https://example.com/kitchen-sink)
- Wiki by slug: [[Guides]]
- Wiki with label: [[About|About this wiki]]
- Autolink: <https://example.net>
- Missing page (red in UI): [[Story55MissingPage]]

## Task list

- [ ] Open task
- [x] Done task

## Lists

- Bullet one
- Bullet two
  - Nested bullet

1. Ordered one
2. Ordered two
   - Nested under ordered

## Table

| Header A | Header B |
|----------|----------|
| Cell **1** | Cell *2* |

## Blockquote

> Quoted line one.
>
> Quoted line two.

## Fenced code

```elm
type Msg = Tick
```

## Thematic break

---

## Hard line break

Line one  
Line two

## Escaping and entities

Use \\*asterisks\\* literally and an entity: &amp;.
"""
