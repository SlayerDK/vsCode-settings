---
name: clean-code
description: >
  Function- and file-level code quality baseline. Use whenever implementing,
  or reviewing code at the unit scale — naming, function size, complexity,
  duplication, comments. Triggers on "review this", "is this clean", "simplify
  this", "find duplication", "refactor", "implement". For
  module- and service-level architecture review (responsibilities, dependencies,
  interface design), use `solid` instead — these skills pair at different scales.
---

# clean-code

Function/file-scale code quality. Applies when writing new code, modifying existing code, or reviewing diffs at the unit level.

For module/service-level concerns — boundaries, responsibilities, dependency direction, interface contracts — defer to `solid`.

## Naming

**Functions need verbs.** The name describes an action, not a noun.

```ts
// bad
function maxHours(start: Date, end: Date) { /* ... */ }
function userData(id: string) { /* ... */ }
function listingPrice(listing: Listing, days: number) { /* ... */ }

// good
function computeMaxHoursInDateRange(start: Date, end: Date) { /* ... */ }
function fetchUserById(id: string) { /* ... */ }
function calculateListingPrice(listing: Listing, days: number) { /* ... */ }
```

**Booleans use `is`, `has`, `can`, or `should`.**

```ts
// bad
const active = user.status === "active";
const permission = checkPermission(user);
const valid = schema.safeParse(input).success;

// good
const isActive = user.status === "active";
const hasPermission = checkPermission(user);
const canEdit = user.role === "admin";
const shouldRetry = err.code === "ECONNRESET";
```



**Avoid empty-calorie words.** `Manager`, `Handler`, `Processor`, `Data`, `Info`, `Util` say nothing about what the thing does.

```ts
// bad
class UserManager { /* ... */ }
function processData(data: unknown) { /* ... */ }
function handleBooking(b: Booking) { /* ... */ }

// good
class UserRepository { /* ... */ }
function normalizeBookingPayload(payload: BookingPayload) { /* ... */ }
function confirmBooking(b: Booking) { /* ... */ }
```

## When writing or modifying code

- **Small, single-purpose functions.** If a function grows past one screen or picks up a second concern, extract.
- **Flat over nested.** Early returns and guard clauses beat pyramids.

```ts
// bad — pyramid of doom
function bookSpot(user: User | null, listing: Listing | null) {
  if (user) {
    if (listing) {
      if (listing.available) {
        if (user.balance >= listing.price) {
          // book
        }
      }
    }
  }
}

// good — guard clauses
function bookSpot(user: User | null, listing: Listing | null) {
  if (!user) throw new Error("user required");
  if (!listing) throw new Error("listing required");
  if (!listing.available) throw new Error("listing unavailable");
  if (user.balance < listing.price) throw new Error("insufficient balance");
  // book
}
```

- **Boring beats clever.** Ternary chains, bitwise tricks, and dense one-liners cost the next reader.

```ts
// bad
const status = user ? (user.active ? (user.role === "admin" ? "admin-active" : "user-active") : "inactive") : "anon";

// good
if (!user) return "anon";
if (!user.active) return "inactive";
return user.role === "admin" ? "admin-active" : "user-active";
```

- **Solve today's problem.** No hypothetical flexibility, no parameters nobody passes, no abstractions for use cases that don't exist.
- **Single source of truth.** Define logic, types, schemas, and constants once. Reference, don't copy.
- **Default to no comments.** Add one only when the *why* is non-obvious — a hidden constraint, an invariant, a workaround. Never explain *what*.

```ts
// bad — restates the code
// increment counter
counter += 1;

// bad — explains "what"
// loop through users and filter active ones
const active = users.filter((u) => u.isActive);

// good — explains a non-obvious "why"
// Payments are stored in minor units (øre); round before scaling to avoid
// float drift on amounts like 12.10 DKK.
const amountInMinorUnits = Math.round(amount * 100);
```

- **Delete what isn't used.** Dead code is noise.

## When reviewing code

For each finding: quote the specific code, explain the issue, suggest a concrete fix. Lead with what matters most; don't nitpick what's already clear.

**Duplication**

- Copy-paste blocks across files or functions → extract a named function
- Parallel type definitions (interface + Zod schema + DB type) → one source, derive the rest (e.g. `z.infer<typeof Schema>`)
- Hard-coded values repeated across files → constant
- Re-implemented utilities that duplicate framework or existing helpers

**Complexity**

- Functions that need scrolling
- Deep nesting — conditions inside conditions inside loops
- Unnecessary abstraction — interface with one impl, factory that builds one type, wrapper that just delegates
- Premature generalization — parameters or branches no caller exercises
- Cleverness that takes more than a few seconds to parse

**Clarity**

- Opaque names; names that don't match what the function does
- Mixed responsibilities in one function
- Commented-out code; comments that explain *what* instead of *why*

Close with the one or two changes that matter most.

## DRY judgment

The rules above push toward removing duplication. Counter-pressures worth respecting:

- **Rule of three.** Two near-identical blocks aren't yet a violation. Wait for the third occurrence — that's when the right shape of the abstraction becomes visible.
- **Coincidental similarity isn't duplication.** Two functions that *currently* look alike but encode different domain rules will diverge. Don't unify them.
- **Business rules consolidate to one layer.** Validation, authorization, pricing — pick one place per rule. If a controller and a service both validate the same input, one of them shouldn't.
- **Don't DRY across boundaries.** Shared abstractions that couple modules which should be independent force lockstep change.

## Gotchas

- **Extraction has a cost.** Three short related lines shouldn't always become a helper — every extraction adds a name to learn and a file to jump to. Extract when the inline version obscures intent, not just to shorten a function.
- **`get` is overloaded.** Prefer `fetch` for I/O, `find` for collection lookup, `compute`/`derive` for pure transforms. Reserve `get` for trivial property access.
- **Pluralization signals collection-ness.** `user` is one user, `users` is a list. Don't name a list `userData` or `userInfo`.
- **Avoid double negatives in booleans.** `isNotInactive` is unreadable — invert to `isActive`.
- **Names that lie.** A function called `validateBooking` that also writes to the database is lying. Rename or split.
- **Test code can repeat.** Three explicit test cases are often easier to read than one parametrized loop you have to mentally unwrap. Don't DRY tests aggressively.
- **`unknown` over `any`.** `any` opts out of the type system; `unknown` forces narrowing. Don't reach for `any` to silence TS errors.
- **Don't log-and-rethrow.** Either handle the error or let it propagate. Logging at every layer buries the same error three times in the stack trace.
- **Magic numbers/strings stay magic until named.** `if (booking.status === 3)` should be `if (booking.status === BookingStatus.Confirmed)`. Same for timeouts, retry counts, fee percentages (`PLATFORM_COMMISSION = 0.15`).
- **No abbreviations the reader has to decode.** `usr`, `lst`, `bkng` save four keystrokes and cost every future reader a glance. The exceptions are well-known conventions (`id`, `url`, `db`, `ctx`).

## Scale boundary

If a finding is about **module boundaries, service responsibilities, dependency direction, or interface contracts**, that's a `solid` concern, not this skill. Note it briefly and stop — don't duplicate what `solid` will cover when it runs.
