---
name: solid
description: >
  Module- and service-level architecture review of backend/server-side code
  against the five SOLID principles (SRP, OCP, LSP, ISP, DIP). Use for
  "review architecture", "audit service/module design", "check SOLID",
  "/solid", or when reviewing files under `apps/web/app/**/actions.ts`,
  `apps/web/app/**/route.ts` or `apps/web/lib/`.
  Pairs with `clean-code` — that skill reviews at the function/file level;
  this one at the module/service level. When both fire, produce
  complementary findings, not duplicates.
---

# solid

Module- and service-level architecture review against SOLID. Backend/server-side first.

**Pairs with `clean-code`.** That skill covers function/file-level concerns — naming, function size, duplication, simplicity. This one covers module-level concerns — responsibilities, dependencies, interface design. When both fire on the same diff, restrict your output to architectural findings and let `clean-code` cover the rest.

Find real structural problems that will cause pain as the codebase grows. If the design is sound, say so; if not, call out violations with concrete refactoring suggestions.

## Scope: server-side first, frontend lightly

SOLID principles originate from object-oriented design and apply most directly to backend/server-side code — service layers, route handlers, database access, business logic, API integrations, middleware, and shared server utilities. This is where violations cause the most pain and where the review should go deepest.

Frontend components (`.tsx`, `.jsx` files) are still worth reviewing, but with a lighter touch. Don't hold component files to the same standard as server modules — UI code has different design pressures (composition, reactivity, rendering). Only flag frontend SOLID issues when they are clear and significant: a component that has grown into a god file with 5+ responsibilities, business logic that belongs in a service layer, or tightly coupled data access that makes the component untestable. Minor prop interface quibbles or UI decomposition preferences are not SOLID concerns.

In a Next.js project, prioritize like this:

- **Primary focus (strict)**: `app/**/actions.ts`, `app/**/route.ts`, `app/proxy.ts`, everything in `lib/`, `lib/repositories/`, `lib/cache/`, Zod schemas, shared types, middleware
- **Secondary focus (lenient)**: Page and layout components, UI components — only flag clear, high-impact violations

## The five principles

Apply each principle thoughtfully. Not every principle applies to every piece of code. Focus on the ones that actually matter for the code at hand.

### S — Single Responsibility Principle (SRP)

**"A class/module should have one, and only one, reason to change."**

A "reason to change" means one actor or stakeholder whose requirements could cause the code to be modified. Most commonly violated, highest practical impact.

What to look for:

- Route handlers (`actions.ts`, `route.ts`) that mix validation, business logic, authorization, and database queries — these should delegate to service/repository layers
- Service modules that handle both business rules and infrastructure (e.g., a user service that also sends email)
- God files — any server-side file over ~200 lines deserves SRP scrutiny
- Utility files that are catch-all dumping grounds

**Example.**

```ts
// bad — actions.ts mixes parsing, authz, persistence, response shaping
export async function createBooking(formData: FormData) {
  const parsed = BookingSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: parsed.error.flatten() };
  const session = await auth();
  if (!session) return { error: "unauthorized" };
  const overlap = await db.booking.findFirst({
    where: { listingId: parsed.data.listingId, /* ... */ },
  });
  if (overlap) return { error: "overlap" };
  return { booking: await db.booking.create({ data: parsed.data }) };
}

// good — the action orchestrates; each concern lives in its own module
export async function createBooking(formData: FormData) {
  const input = parseBookingInput(formData);
  const userId = await requireAuthenticatedUserId();
  return { booking: await bookingService.create(userId, input) };
}
```

### O — Open/Closed Principle (OCP)

**"Software entities should be open for extension, but closed for modification."**

Adding new behavior shouldn't require editing existing, tested code. In TypeScript: discriminated unions, strategy patterns, handler maps, and configuration objects achieve OCP without class hierarchies.

What to look for:

- Long `if/else` or `switch` chains that would need a new branch per new variant
- Functions that take a `type` string parameter and branch on it
- Error handling duplicated across every route handler instead of being composable
- Adding a new feature requiring edits in multiple existing files

**Example.**

```ts
// bad — every new listing type means editing this switch
function calculatePrice(listing: Listing, days: number) {
  switch (listing.type) {
    case "recurring":
      return listing.weeklyRate * Math.ceil(days / 7);
    case "single":
      return listing.dailyRate * days;
    default:
      throw new Error("unknown listing type");
  }
}

// good — each variant owns its pricing; the dispatcher is closed for modification
const pricingStrategies: Record<ListingType, (l: Listing, d: number) => number> = {
  recurring: (l, d) => l.weeklyRate * Math.ceil(d / 7),
  single: (l, d) => l.dailyRate * d,
};

function calculatePrice(listing: Listing, days: number) {
  return pricingStrategies[listing.type](listing, days);
}
```

### L — Liskov Substitution Principle (LSP)

**"Subtypes must be substitutable for their base types without altering program correctness."**

Applies to: classes extending classes, objects implementing interfaces, functions accepting union or generic types, and service implementations satisfying an interface contract.

What to look for:

- Type guards or `instanceof` checks immediately after receiving a value typed as the base
- Implementations that throw `NotImplementedError` for inherited methods, or no-op them
- Functions accepting a union type but special-casing some members in a way that breaks shared callers
- Repository or service interfaces where some implementations silently ignore certain operations

**Example.**

```ts
// bad — the cache impl pretends to be a repository but can't fulfil the contract
interface BookingRepository {
  findById(id: string): Promise<Booking>;
}

class CachedBookingRepository implements BookingRepository {
  async findById(id: string): Promise<Booking> {
    const cached = this.cache.get(id);
    if (!cached) throw new Error("not in cache"); // base promises a lookup; this can't always
    return cached;
  }
}

// good — the cache wraps a real repo; the interface is honoured for any input
class CachedBookingRepository implements BookingRepository {
  constructor(private readonly cache: Cache, private readonly source: BookingRepository) {}
  async findById(id: string): Promise<Booking> {
    return this.cache.get(id) ?? this.source.findById(id);
  }
}
```

### I — Interface Segregation Principle (ISP)

**"No client should be forced to depend on interfaces it does not use."**

Keep types, interfaces, and service contracts focused. A function that only needs a user's ID shouldn't accept an entire `User` object with 20 fields.

What to look for:

- Service functions receiving whole entity objects but only reading one or two properties
- Large "god" interfaces many consumers depend on but each uses a subset
- API response types exposing internal database structure when consumers only need a subset
- Route loaders returning full DB entities to the client when only specific fields are needed (data leakage risk)

**Example.**

```ts
// bad — service couples to all of User to read one field
async function sendBookingConfirmation(user: User, booking: Booking) {
  await mailer.send(user.email, renderConfirmation(booking));
}

// good — narrow the contract; callers don't need a whole User
async function sendBookingConfirmation(recipientEmail: string, booking: Booking) {
  await mailer.send(recipientEmail, renderConfirmation(booking));
}
```

### D — Dependency Inversion Principle (DIP)

**"High-level modules should not depend on low-level modules. Both should depend on abstractions."**

Business logic shouldn't directly import database clients, HTTP libraries, or framework-specific utilities. Define what the business logic *needs* (as a type/interface), and let infrastructure satisfy it. This most directly affects testability and maintainability.

What to look for:

- Route handlers or server actions importing `db` / `prisma` and writing raw ORM queries inline instead of going through `lib/repositories/`
- Business logic files calling `fetch()` directly for external APIs with no boundary
- Hard-to-test code — if you can't test a function without standing up a database or mocking HTTP, that's a DIP smell
- Authorization logic embedded in route handlers instead of extracted into reusable middleware or service functions

**Example.**

```ts
// bad — business logic reaches into infrastructure directly
import { db } from "@/lib/db";

export async function bookSpot(userId: string, listingId: string) {
  const listing = await db.listing.findUnique({ where: { id: listingId } });
  if (!listing) throw new Error("listing not found");
  return db.booking.create({ data: { userId, listingId } });
}

// good — depend on a narrow interface; infrastructure satisfies it
interface ListingRepository {
  findById(id: string): Promise<Listing | null>;
}
interface BookingRepository {
  create(input: { userId: string; listingId: string }): Promise<Booking>;
}

export async function bookSpot(
  userId: string,
  listingId: string,
  deps: { listings: ListingRepository; bookings: BookingRepository },
) {
  const listing = await deps.listings.findById(listingId);
  if (!listing) throw new Error("listing not found");
  return deps.bookings.create({ userId, listingId });
}
```

## Gotchas

- **One impl ≠ one interface.** Don't add an interface "for testability" if there's only one implementation. TypeScript lets you pass functions or mock at the module boundary without ceremony. Wait until a second implementation actually exists.
- **DIP doesn't require a DI container.** Passing dependencies as function arguments (or constructor args) is enough in TS. Containers are overhead — only worth it at scale.
- **OCP isn't a license to over-abstract.** Don't extract a strategy pattern for "future variants" that may never come. Wait for the second variant before generalizing — the right abstraction is invisible until then.
- **SRP's "one reason to change" is not "one thing".** A module can have many functions and still satisfy SRP if they all serve one actor (e.g., the billing team's rules). Don't atomize modules just because they have multiple exports.
- **ISP applies to parameters, not just interfaces.** Take `{ id, email }` not the whole `User` when that's all the function needs. Smaller param surface = less coupling, easier to call from tests.
- **A folder of small files can still be a god module.** Splitting `userService.ts` into 12 files inside `lib/user/` doesn't fix mixed responsibilities — it hides them. Look at what the *module* does, not how many files it has.
- **LSP isn't just about classes.** Discriminated unions, generic type parameters, and function-shaped interfaces all have substitution contracts. A `(req: BaseRequest) => Response` that throws for some valid `BaseRequest` shapes is an LSP violation.
- **Repositories are about boundaries, not types.** A "repository" that's a thin wrapper around `db.x.findUnique` with no value added is ceremony. Repositories earn their keep when they hide ORM specifics, enforce invariants, or combine queries — not when they just rename them.
