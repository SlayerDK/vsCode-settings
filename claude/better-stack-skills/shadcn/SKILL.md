---
name: shadcn
description: >
  Reference and usage guide for shadcn/ui — a collection of accessible, themeable UI components
  for React and Next.js built with TypeScript, Tailwind CSS, and Radix UI primitives. Use this
  skill whenever the user is building UI in React/Next.js, asks for a component (button, dialog,
  form, sidebar, table, etc.), installs or configures shadcn/ui, runs the shadcn CLI, edits
  components.json, sets up theming or dark mode, or works with a shadcn registry. Trigger on:
  "shadcn", "shadcn/ui", "add a component", "install shadcn", "components.json", "Radix UI",
  "Tailwind theming", "registry item", any mention of a specific shadcn/ui component, or any UI
  work in a React/Next.js project where shadcn/ui is the required component library.
---

# shadcn/ui

> shadcn/ui is a collection of beautifully-designed, accessible components for React and Next.js.
> Built with TypeScript, Tailwind CSS, and Radix UI primitives. Open Source. Open Code. AI-Ready.

## How to use this skill

- Add components using the CLI: `pnpm dlx shadcn@latest add <component>`
- For project setup, follow the Next.js installation guide.
- Prefer the CLI over manual copy-paste when adding components.
- Component variants in this repo use `cva()` from `class-variance-authority` (already installed).
- When working in this repo, treat shadcn/ui as the required UI library (see `CLAUDE.md` → Tech Stack).

## Overview

- [Introduction](https://ui.shadcn.com/docs): About shadcn/ui.
- [Changelog](https://ui.shadcn.com/docs/changelog): Latest updates.
- [CLI](https://ui.shadcn.com/docs/cli): Use the shadcn CLI to add components.
- [components.json](https://ui.shadcn.com/docs/components-json): Configuration reference.
- [Theming](https://ui.shadcn.com/docs/theming): CSS Variables for theming.
- [Dark mode](https://ui.shadcn.com/docs/dark-mode/next): Next.js dark mode with `next-themes`.

## Installation

- [Next.js](https://ui.shadcn.com/docs/installation/next): Setup in Next.js.
- [Vite](https://ui.shadcn.com/docs/installation/vite): Setup in Vite.
- [Remix](https://ui.shadcn.com/docs/installation/remix): Setup in Remix.
- [Astro](https://ui.shadcn.com/docs/installation/astro): Setup in Astro.
- [Manual](https://ui.shadcn.com/docs/installation/manual): Manual setup without CLI.

## Components

### Form & Input
- [Button](https://ui.shadcn.com/docs/components/button)
- [Input](https://ui.shadcn.com/docs/components/input)
- [Textarea](https://ui.shadcn.com/docs/components/textarea)
- [Checkbox](https://ui.shadcn.com/docs/components/checkbox)
- [Radio Group](https://ui.shadcn.com/docs/components/radio-group)
- [Select](https://ui.shadcn.com/docs/components/select)
- [Switch](https://ui.shadcn.com/docs/components/switch)
- [Slider](https://ui.shadcn.com/docs/components/slider)
- [Form](https://ui.shadcn.com/docs/components/form) — React Hook Form integration
- [Label](https://ui.shadcn.com/docs/components/label)
- [Input OTP](https://ui.shadcn.com/docs/components/input-otp)

### Layout & Navigation
- [Accordion](https://ui.shadcn.com/docs/components/accordion)
- [Breadcrumb](https://ui.shadcn.com/docs/components/breadcrumb)
- [Card](https://ui.shadcn.com/docs/components/card)
- [Collapsible](https://ui.shadcn.com/docs/components/collapsible)
- [Navigation Menu](https://ui.shadcn.com/docs/components/navigation-menu)
- [Pagination](https://ui.shadcn.com/docs/components/pagination)
- [Resizable](https://ui.shadcn.com/docs/components/resizable)
- [Scroll Area](https://ui.shadcn.com/docs/components/scroll-area)
- [Separator](https://ui.shadcn.com/docs/components/separator)
- [Sheet](https://ui.shadcn.com/docs/components/sheet)
- [Sidebar](https://ui.shadcn.com/docs/components/sidebar)
- [Tabs](https://ui.shadcn.com/docs/components/tabs)

### Overlays & Dialogs
- [Alert Dialog](https://ui.shadcn.com/docs/components/alert-dialog)
- [Dialog](https://ui.shadcn.com/docs/components/dialog)
- [Drawer](https://ui.shadcn.com/docs/components/drawer)
- [Dropdown Menu](https://ui.shadcn.com/docs/components/dropdown-menu)
- [Context Menu](https://ui.shadcn.com/docs/components/context-menu)
- [Hover Card](https://ui.shadcn.com/docs/components/hover-card)
- [Popover](https://ui.shadcn.com/docs/components/popover)
- [Tooltip](https://ui.shadcn.com/docs/components/tooltip)

### Feedback & Status
- [Alert](https://ui.shadcn.com/docs/components/alert)
- [Badge](https://ui.shadcn.com/docs/components/badge)
- [Progress](https://ui.shadcn.com/docs/components/progress)
- [Skeleton](https://ui.shadcn.com/docs/components/skeleton)
- [Sonner](https://ui.shadcn.com/docs/components/sonner) — Toast notifications
- [Toast](https://ui.shadcn.com/docs/components/toast)

### Display & Media
- [Avatar](https://ui.shadcn.com/docs/components/avatar)
- [Aspect Ratio](https://ui.shadcn.com/docs/components/aspect-ratio)
- [Calendar](https://ui.shadcn.com/docs/components/calendar)
- [Carousel](https://ui.shadcn.com/docs/components/carousel)
- [Chart](https://ui.shadcn.com/docs/components/chart)
- [Command](https://ui.shadcn.com/docs/components/command)
- [Data Table](https://ui.shadcn.com/docs/components/data-table)
- [Date Picker](https://ui.shadcn.com/docs/components/date-picker)
- [Table](https://ui.shadcn.com/docs/components/table)

### Misc
- [Toggle](https://ui.shadcn.com/docs/components/toggle)
- [Toggle Group](https://ui.shadcn.com/docs/components/toggle-group)

## Tailwind v4 Notes

This repo uses Tailwind v4. Key differences from v3:

- All theme customisation lives in `@theme {}` inside `app/globals.css` — no `tailwind.config.js`.
- Import: `@import "tailwindcss"` (not `@tailwind base; @tailwind components; @tailwind utilities`).
- PostCSS plugin: `@tailwindcss/postcss` (not `tailwindcss`).
- Container queries are built-in: `@container` with `@sm:`, `@md:` variants.
- CSS variables are defined in `@theme {}` and follow the `--color-*` naming convention.

## Dark Mode

This repo uses CSS variable-based dark mode. Toggle the `dark` class on the `<html>` element. For Next.js, install `next-themes`:

```bash
pnpm add next-themes
```

Then wrap your layout with `ThemeProvider`:

```tsx
import { ThemeProvider } from 'next-themes'

export default function RootLayout({ children }) {
  return (
    <html suppressHydrationWarning>
      <body>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
```
