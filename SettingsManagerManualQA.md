# HimmerFlow — Settings Manager Manual QA

Use this checklist when adding a UI test target or manually verifying the Settings configuration flow.

## Towers & Areas

- Open Settings and confirm the Towers & Areas section is visible.
- Tap Add Tower / Area and confirm the editor sheet opens.
- Tap Save Tower / Area with an empty name and confirm “Tower / area name is required.” appears.
- Add a unique active tower / area with 12 delivery floors and confirm it appears in Settings.
- Confirm active custom towers appear in the HomeView tower picker on the Linen tab (inline picker, not a separate tower-selection screen).
- Toggle a custom tower inactive and confirm Settings shows the inactive helper copy.
- Confirm protected route towers show Protected Route and locked delivery floors.

## Linen Items

- Open Settings and confirm the Linen Items section is visible.
- Tap Add Linen Item and confirm the editor sheet opens.
- Tap Save Linen Item with an empty name and confirm “Item name is required.” appears.
- Add a unique active item with Manual Pieces, target per delivery floor 4, PCS per bundle 5, and all tower / area availability.
- Confirm the custom item appears in Settings and during receiving.
- Toggle a custom item inactive and confirm it is hidden during receiving.
- Confirm duplicate Bath Towel or duplicate item names are rejected.

## Logs

- Confirm Daily Logs filters always show All and Shortages.
- Confirm saved custom tower / area names appear as filters after logs are saved.
- Confirm deleting logs does not leave the filter bar in a broken state.
