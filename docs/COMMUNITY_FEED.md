# Community feed

Account → Learning teams → Community feed reads public kind-1 `#LearnWithNostr` milestones and kind-0 author metadata from the existing learning-team relays. Multiple posts by one author remain distinct; event IDs deduplicate relay copies. All signatures and requested tags/kinds/authors are checked by the shared relay client before display. The latest metadata event determines the name.

The feed follows `TeamFeed.jsx`: hide the five test names, recognize question milestones (120 steps), XP-purpose tags and “I just reached” text, show goal percentages, and link author profiles through Ditto. Scholarship notices are displayed as text, including their external links. HTTP/HTTPS links open externally. Missing/invalid numeric tags show no invented statistic. Both hashtag spellings are queried because the source's reader uses title case while its XP publisher emits lowercase.

Refresh coalesces concurrent reads and caches nonempty results for two minutes, empty results for fifteen seconds. A forced refresh bypasses the cache. Failed reads preserve existing posts; changing account clears the cache and cancels pending work. If profiles cannot be fetched, posts remain readable with the source fallback name. Navigating away cancels reads.

Share my progress opens a preview containing only the active language, total XP, daily XP/goal and public product link. Publishing requires a separate explicit button. The signed kind-1 post uses the web publisher's text and tags, including lowercase `learnwithnostr`. No private notes, drafts, membership or companion memory are included. Opening, refreshing or cancelling the preview never publishes. Existing public team progress remains a separate kind-30078 snapshot. Automatic milestone posting is not enabled by this control.

Verification uses a loopback WebSocket relay and disposable identities. No public community event is sent by tests. `scripts/export-community-fixtures.mjs` executes the reference's pure name/question filters to export 42 comparisons without modifying the source checkout.
