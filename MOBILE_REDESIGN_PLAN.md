# Mobile Redesign Plan — Admin + Payroll App

## Objective
Create a mobile-first redesign for the HR & Payroll admin experience while preserving the existing payroll, contractor, and reconciliation workflows.

The current admin app is implemented in `app/index.html` as a single-file React app. It is functional and partially responsive, but the admin workflows are still desktop-oriented, with wide tables, dense cards, and a top-heavy navigation structure.

The contractor portal at `portal/index.html` already has a much more mobile-friendly layout, which gives us a useful visual and structural reference.

---

## Scope
- Admin app (`app/index.html`) mobile redesign
- Payroll workflow screens: pay period selection, calculate, review, lock, and Wise payout flow
- Contractor roster + profile editing experience for admin users
- Supporting admin configuration screens (portal settings, contractors, documents, etc.)
- Preserve existing Supabase auth, RLS, and edge-function-backed workflows

## Goals
1. Make the admin experience comfortable on phone screens
2. Keep the core payroll flow intact and visible
3. Convert wide tables into mobile-friendly cards / accordions / stacked rows
4. Keep UI states clear: loading, error, empty, pending payroll, locked payroll
5. Maintain a single-page React approach for fast iteration

## Current findings
- `app/index.html` uses inline CSS and custom React components with a desktop-first layout
- Wide tables are wrapped in `.table-scroll`, but many screens remain dense and not optimized for mobile
- The portal app already has a compact mobile-first layout and can guide styling/navigation decisions
- The admin app has a topbar + tabs + content cards; a more mobile-friendly version needs a simpler menu and smaller interaction targets

## Phase 1 — Discovery & design
- Audit admin screens in `app/index.html` and list high-priority mobile workflows
- Identify the most important admin actions for a phone user:
  - Open and review current payroll period
  - Calculate payroll and lock the period
  - Start Wise payout / reconcile with Wise
  - Search and open contractors
  - Edit contractor profile fields
- Define mobile navigation pattern (bottom nav, drawer, or stacked card menu)
- Choose mobile-friendly UI patterns for:
  - contractor roster
  - pay period cards
  - action buttons
  - collapsible detail sections
  - filters and search

## Phase 2 — Implementation
- Refactor global app shell to support mobile-first layout:
  - sticky header with a compact menu
  - bottom action bar or mobile tab bar if needed
  - narrower cards and reduced padding on small screens
- Replace desktop tables with responsive components:
  - contractor list → card list with key columns visible
  - payroll summary → summary cards and expandable details
  - time import controls → stacked action cards
- Improve small-screen interactions:
  - larger touch targets for buttons and row actions
  - shorter form fields with clear labels
  - use accordions for dense contractor details and payroll line items
- Preserve desktop/tablet layout for wider screens using CSS breakpoints

## Phase 3 — Polish & QA
- Test on real phone viewport widths and Safari / Chrome mobile simulators
- Validate flows end-to-end:
  - sign in via Google (admin auth)
  - search contractors and open profile
  - run payroll calculation and lock period
  - draft Wise payout and inspect status
- Confirm admin-only pages remain secure and data flow is unchanged
- Update any docs or setup notes if the UI changes affect user instructions

## Immediate next actions
1. Open `app/index.html` and review the current admin tabs + screen hierarchy.
2. Create a mobile admin wireframe or sketch the new screen structure.
3. Refactor the top-level layout to use mobile-optimized containers and spacing.
4. Convert the highest-value admin screen first: payroll summary and contractor list.
5. Test the new layout in a phone viewport and iterate.

## Notes
- Keep the same project architecture: single-file React in-browser Babel, with Supabase frontend/backing services
- Use the contractor portal styles and mobile layout as a reference for a cleaner admin experience
- Avoid changing business logic until the mobile shell and navigation are stable
