# Accessibility

## Built in
| Need | What the app does |
|---|---|
| VoiceOver | Each expense is one stop read as a sentence ("Tim Hortons, Eating out, $12.50"); budget rows say spent, percent used and money left |
| Not colour alone | Budget states have a symbol (✓, ⚠, ✕) and words ("Over by $20.00") as well as a colour |
| Dynamic Type | System text styles everywhere; `AdaptiveRow` stacks rows at accessibility sizes so nothing is cut off |
| Contrast | Custom colours for text are at least 4.5:1 in light and dark mode |
| Charts | Every bar and point has a VoiceOver label and value; Swift Charts adds an audio graph |
| Headings | The month title is a heading, so the rotor can jump to it |
| Widget | Read as one sentence: "Spent $1,243.50 this month of $2,000.00" |

## Automated audit
`AccessibilityAuditTests` runs Xcode's `performAccessibilityAudit()` on each screen.

<!-- auto:a11y-audit -->
_Not generated yet. Run `bash pocket-budget-lab.sh evidence`._
<!-- /auto:a11y-audit -->

## Manual checks (do these yourself)
- Turn on VoiceOver and add an expense with your eyes closed.
- Set the largest text size and check every tab.
- Turn on greyscale (Settings > Accessibility > Display & Text Size > Colour Filters): can you still tell which budget is over?
