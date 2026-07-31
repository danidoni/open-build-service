# Issue Tracker: Trello (manual)

Issues are tracked in Trello. There is no single inbox board — tickets are routed
to the appropriate board by the person creating them.

## How skills interact with this tracker

Skills do **not** create Trello cards automatically. Instead, when a skill needs
to publish a ticket, it produces a **manual checklist** with:

- Card title
- Card description (what to build, acceptance criteria)
- Blocking edges (which other cards must be done first)
- Suggested label / status

You then create the card in the appropriate Trello board.

## Known boards

- **BS Sprint** — default sprint board (add others here as you identify them)

## Wayfinding operations

Used by the `wayfinder` skill. All operations are manual — skills produce the
content; you create and update cards in Trello.

- **Create map:** Create a Trello card manually; note its URL in the conversation
  so the skill can reference it.
- **Create child ticket:** Create a card in the appropriate board; paste its URL
  into the map card's description or checklist.
- **Blocking edges:** Use Trello's card linking, or add a checklist item on the
  blocked card referencing the blocking card's URL.
- **Claim a ticket:** Assign yourself to the card in Trello before starting work.
- **Close a ticket:** Archive the card in Trello when resolved.
- **Frontier query:** Scan your boards for unarchived, unassigned cards — first
  unblocked one in dependency order is the next ticket to work.

## Limitations

Wayfinding operations are not automated. The skill will narrate what to do and
wait for you to confirm each Trello action before continuing.
