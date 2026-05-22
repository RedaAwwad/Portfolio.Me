---
name: react
description: >
  Senior-level React best practices agent skill for Antigravity. Use this skill whenever
  working on a React application — whether starting a new project, reviewing code, auditing
  performance, planning folder structure, refactoring, writing tests, or enforcing security.
  Triggers on: React component creation, performance review, bundle optimization, state
  management decisions, folder/project structure planning, TypeScript setup, testing strategy,
  security hardening, code review, or any question about "how should we build this in React".
  Apply proactively — do not wait for an explicit request.
---

# React Best Practices — Antigravity Agent Skill

> Authored from the perspective of a Senior Frontend Developer with 8+ years of React experience.  
> Last researched: April 2026 | Covers React 19, Next.js 15, Vite 6, TypeScript 5+

---

## 1. Performance Optimization

### 1.1 Measure Before You Optimize

Never guess. Profile first using:
- **React DevTools Profiler** — identify which components re-render and why
- **Chrome DevTools Performance tab** — timeline of scripting, rendering, paint events
- **Lighthouse / Lighthouse CI** — target scores: 90+ Performance, 100 Accessibility, 90+ Best Practices
- **Core Web Vitals targets**: FCP < 1.8s, LCP < 2.5s, CLS < 0.1, INP < 100ms

### 1.2 Re-render Control

Every state update triggers a re-render of the owning component and all its children. Control this aggressively.

```tsx
// Memoize components to prevent re-renders when props haven't changed
const Button = React.memo(({ onClick, label }: ButtonProps) => (
  <button onClick={onClick}>{label}</button>
));

// Memoize callbacks passed as props
const handleClick = useCallback(() => {
  doSomething();
}, [dependency]);

// Memoize expensive computations
const sortedList = useMemo(() => expensiveSort(rawList), [rawList]);
```

**Rules of thumb:**
- Keep state as local as possible — state high in the tree causes global re-renders
- Store only minimum required state; derive everything else
- Split large components into smaller, isolated units to create "re-render firewalls"
- Avoid unnecessary state — derived values don't need their own `useState`

### 1.3 React Compiler (React 19+)

The React Compiler auto-memoizes components and hooks. For most apps, it delivers **30–60% reduction** in unnecessary re-renders. Enable it in Babel or Vite config and remove manual `memo`/`useMemo`/`useCallback` where the compiler handles it. Apps with no prior optimization see 50–80% improvement.

### 1.4 Code Splitting & Lazy Loading

Never ship the entire app upfront.

```tsx
const Dashboard = React.lazy(() => import('./Dashboard'));

function App() {
  return (
    <React.Suspense fallback={<Spinner />}>
      <Dashboard />
    </React.Suspense>
  );
}
```

- Route-level splitting is the highest-impact starting point
- Dynamically import heavy libraries (e.g., charting, PDF, rich-text editors) on demand
- For SSG/SSR with Next.js: SSG cuts load times 60–80% vs CSR; SSR reduces perceived load 40–60%

### 1.5 List Virtualization

Never render thousands of DOM nodes at once.

```tsx
import { FixedSizeList as List } from 'react-window';

<List height={400} itemCount={items.length} itemSize={35} width="100%">
  {({ index, style }) => <div style={style}>{items[index].name}</div>}
</List>
```

Use `react-window` or `react-virtualized` for any list with 50+ items.

### 1.6 Context Optimization

Context re-renders every consumer when its value changes — even if the consuming component only uses part of the data.

- Split contexts by update frequency: `ThemeContext`, `AuthContext`, `NotificationContext` separately
- Use `useMemo` to stabilize context value objects
- For frequently-changing state, prefer Zustand, Jotai, or Redux Toolkit over Context

### 1.7 Concurrent Rendering (React 18+)

```tsx
const [isPending, startTransition] = useTransition();

startTransition(() => {
  setSearchResults(filterData(query)); // non-urgent update
});
```

Use `useTransition` for non-urgent state updates (search filters, tab switches) to keep the UI responsive.

### 1.8 Bundle Size

- **Tree-shake** by using named imports: `import { debounce } from 'lodash-es'` not `import _ from 'lodash'`
- Analyze bundle with `webpack-bundle-analyzer` or Vite's `rollup-plugin-visualizer`
- Replace heavy libraries with lighter alternatives where possible (e.g., `date-fns` over `moment`)
- Prefer `next/image` or equivalent for image optimization — unoptimized images are a top LCP killer

### 1.9 Performance Priority Order

Focus here first (60–80% of gains, minimal effort):
1. React Compiler
2. Code splitting at route level
3. Image optimization
4. Proper state management architecture

Save these for specific profiled bottlenecks:
5. Web Workers for CPU-heavy tasks
6. Advanced SSR/streaming
7. Manual micro-optimizations

---

## 2. Scalable App Structure

### 2.1 Core Principle: Feature-Based Organization

Organize by **feature/domain**, not by file type. Type-based (`/components`, `/hooks`) works for ≤15 components. Beyond that, it breaks down.

```
src/
├── app/                    # App entry, router, global providers
│   ├── store.ts
│   ├── rootReducer.ts
│   └── router.tsx
│
├── components/             # Truly shared, reusable UI only
│   ├── common/
│   │   ├── Button/
│   │   │   ├── Button.tsx
│   │   │   ├── Button.types.ts
│   │   │   ├── Button.test.tsx
│   │   │   └── Button.module.css
│   │   └── Modal/
│   └── layout/
│       ├── Header.tsx
│       └── Sidebar.tsx
│
├── features/               # Feature-scoped: components + logic together
│   ├── auth/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── services/
│   │   ├── authSlice.ts
│   │   └── auth.types.ts
│   └── dashboard/
│       ├── components/
│       ├── hooks/
│       └── dashboardSlice.ts
│
├── pages/                  # Route-level page components
│   ├── Login/
│   └── Dashboard/
│
├── hooks/                  # App-wide custom hooks
├── services/               # API clients, external integrations
│   ├── apiClient.ts
│   ├── auth.service.ts
│   └── user.service.ts
│
├── queries/                # React Query / TanStack Query logic
├── store/                  # Global state (Redux, Zustand)
├── context/                # React Context providers (for stable, low-frequency state)
├── utils/                  # Pure functions, helpers, constants
├── types/                  # Shared TypeScript types/interfaces
├── styles/                 # Global CSS, theme tokens, design system
├── assets/                 # Images, fonts, icons
└── config/                 # Env vars, feature flags, app config
```

### 2.2 Component Co-location

For non-trivial components, keep all related files together:

```
features/incidents/
├── components/
│   └── IncidentList/
│       ├── IncidentList.tsx
│       ├── IncidentList.test.tsx
│       ├── IncidentList.stories.tsx
│       ├── IncidentList.module.css
│       └── index.ts          ← re-exports only
```

### 2.3 Absolute Imports

Configure `tsconfig.json` to avoid `../../../` path hell:

```json
{
  "compilerOptions": {
    "baseUrl": "src",
    "paths": {
      "@components/*": ["components/*"],
      "@features/*": ["features/*"],
      "@hooks/*": ["hooks/*"],
      "@utils/*": ["utils/*"]
    }
  }
}
```

Usage: `import Button from '@components/common/Button'`

### 2.4 Index Files

Use `index.ts` barrel files **within feature folders only** to define the public API of a feature. Avoid global barrel files (they can harm tree-shaking and create circular dependency traps).

### 2.5 Scalability Rules

- Plan feature-based structure from day one — refactoring folder structure later is expensive
- Keep features as "black boxes": internal logic is private, only export what other features need
- Avoid deeply nested component trees — flatten where possible
- Separate stateful (smart) containers from presentational (dumb) components

---

## 3. Coding Best Practices

### 3.1 TypeScript — Always

```tsx
// Define interfaces for all props
interface UserCardProps {
  userId: string;
  displayName: string;
  onSelect: (id: string) => void;
}

const UserCard: React.FC<UserCardProps> = ({ userId, displayName, onSelect }) => (
  <div onClick={() => onSelect(userId)}>{displayName}</div>
);
```

- Enable `strict: true` in `tsconfig.json` — non-negotiable
- Never use `any`; use `unknown` when the type is truly dynamic
- Use `interface` for component props and object shapes; `type` for unions/intersections
- Type all API responses — use tools like `openapi-typescript` to auto-generate from schemas

### 3.2 Custom Hooks

Extract all non-trivial logic from components into custom hooks. A component should primarily render, not compute.

```tsx
// ✅ Good — logic extracted, component stays clean
function useUserData(userId: string) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUser(userId).then(setUser).finally(() => setLoading(false));
  }, [userId]);

  return { user, loading };
}

function UserProfile({ userId }: { userId: string }) {
  const { user, loading } = useUserData(userId);
  if (loading) return <Spinner />;
  return <div>{user?.name}</div>;
}
```

### 3.3 State Management Guidance

| Scenario | Recommendation |
|---|---|
| Local UI state (toggle, form input) | `useState` / `useReducer` |
| Shared simple state, small app | React Context (with memoization) |
| Complex shared state, large app | Zustand |
| Server state, caching, sync | TanStack Query (React Query) |
| Form state | React Hook Form |

Avoid Redux for simple apps — it adds ceremony without benefit.

### 3.4 Naming Conventions

- **Components**: PascalCase — `UserProfileCard.tsx`
- **Hooks**: camelCase with `use` prefix — `useAuthState.ts`
- **Utils/helpers**: camelCase — `formatDate.ts`
- **Constants**: SCREAMING_SNAKE_CASE — `MAX_RETRY_COUNT`
- **Types/Interfaces**: PascalCase — `UserProfile`, `ApiResponse<T>`
- **CSS Modules**: camelCase — `styles.cardWrapper`

### 3.5 Component Design

- **Single Responsibility**: one component does one thing
- **Composition over inheritance**: build with `children` and render props, not class hierarchies
- **Controlled components**: always manage form state explicitly
- **Avoid prop drilling beyond 2 levels** — use Context or a state manager
- **Default exports for pages/routes**, named exports for shared components

### 3.6 Error Boundaries

Wrap all async-rendering sections with Error Boundaries to prevent full app crashes:

```tsx
import { ErrorBoundary } from 'react-error-boundary';

<ErrorBoundary fallback={<ErrorPage />}>
  <FeatureModule />
</ErrorBoundary>
```

### 3.7 Tooling

- **Linting**: ESLint with `@typescript-eslint`, `eslint-plugin-react`, `eslint-plugin-react-hooks`
- **Formatting**: Prettier (enforce with pre-commit hooks via Husky + lint-staged)
- **Build**: Vite (preferred for new projects) or Next.js for SSR/SSG needs
- **Component explorer**: Storybook for shared design system components

---

## 4. Testing Strategy

### 4.1 Testing Pyramid

| Level | Tool | Coverage Target |
|---|---|---|
| Unit tests | Vitest / Jest | Core utils, hooks, reducers |
| Component tests | React Testing Library | User interactions, rendering |
| Integration tests | React Testing Library + MSW | Feature flows, API integration |
| E2E tests | Cypress / Playwright | Critical user journeys |

Target **80%+ test coverage**. Never ship without at least integration tests for critical paths.

### 4.2 React Testing Library Philosophy

Test behavior, not implementation:

```tsx
// ✅ Good — tests what the user sees/does
test('shows error when login fails', async () => {
  render(<LoginForm />);
  fireEvent.click(screen.getByRole('button', { name: /login/i }));
  expect(await screen.findByText(/invalid credentials/i)).toBeInTheDocument();
});

// ❌ Bad — tests implementation detail
test('sets isLoading state to true', () => {
  const { result } = renderHook(() => useLoginForm());
  expect(result.current.isLoading).toBe(false);
});
```

### 4.3 API Mocking

Use **MSW (Mock Service Worker)** for realistic API mocking in both tests and development:

```tsx
// handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users', () => HttpResponse.json([{ id: 1, name: 'Alice' }])),
];
```

### 4.4 Accessibility Testing

- Use `jest-axe` in component tests to catch a11y violations automatically
- Strive for WCAG AA compliance
- Use semantic HTML elements — `<button>`, `<nav>`, `<main>`, `<article>` — not `<div>` for everything
- Add ARIA attributes deliberately, not as a default

---

## 5. Security Best Practices

### 5.1 XSS Prevention

React's JSX auto-escapes `{}` interpolations — this is your first line of defense. Never bypass it.

```tsx
// ✅ Safe — React escapes this
<div>{userInput}</div>

// ❌ Dangerous — only use with sanitized content
<div dangerouslySetInnerHTML={{ __html: sanitize(content) }} />
```

When you must use `dangerouslySetInnerHTML`, always sanitize with **DOMPurify** first:

```tsx
import DOMPurify from 'dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(htmlContent) }} />
```

### 5.2 URL Validation

Never render user-supplied URLs directly:

```tsx
function isValidUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return ['http:', 'https:'].includes(parsed.protocol);
  } catch {
    return false;
  }
}

<a href={isValidUrl(userUrl) ? userUrl : '#'}>Link</a>
```

### 5.3 Authentication & Token Storage

- Store JWT tokens in **httpOnly cookies** (not localStorage) to prevent XSS theft
- Never store sensitive data in `localStorage` or `sessionStorage`
- Use established auth libraries: Auth0, Clerk, Firebase Auth, or NextAuth
- Always enforce HTTPS in production

### 5.4 Dependency Security

```bash
npm audit              # find known vulnerabilities
npm audit fix          # auto-fix where possible
npx snyk test          # deeper scan with Snyk
```

- Integrate `npm audit` into your CI/CD pipeline
- Keep `react` and `react-dom` on latest stable versions
- Review `package.json` regularly — 96% of codebases contain at least one vulnerable OSS dependency (Synopsys 2025)

### 5.5 Content Security Policy (CSP)

Set strict CSP headers on your server/CDN to restrict what scripts can execute. This is the most effective defense against XSS beyond React's own escaping.

### 5.6 SSR Safety

When using SSR, never concatenate unsanitized request data into rendered HTML. Escape JSON blobs embedded in HTML:

```tsx
const safeState = JSON.stringify(preloadedState).replace(/</g, '\\u003c');
// Then inject safeState into a <script> tag
```

---

## 6. Developer Experience & Maintainability

### 6.1 Stay Current

- Follow the [official React blog](https://react.dev/blog) for release notes
- Run `npm outdated` regularly
- Use `react-codemod` for automated migration of deprecated patterns

### 6.2 Documentation

- Document all shared components with Storybook stories
- Use TypeDoc or JSDoc for complex utility functions
- Keep a `DECISIONS.md` or ADR (Architecture Decision Records) for major structural choices

### 6.3 CI/CD Pipeline Checklist

- [ ] `eslint` — lint on every PR
- [ ] `prettier --check` — format check
- [ ] `tsc --noEmit` — TypeScript compile check
- [ ] `vitest run` / `jest` — full test suite
- [ ] `npm audit` — dependency vulnerability scan
- [ ] Lighthouse CI — performance regression detection
- [ ] Bundle size check (fail build if bundle exceeds threshold)

---

## Quick Reference Card

| Concern | Recommended Tool / Approach |
|---|---|
| Build tool | Vite (SPA) / Next.js (SSR/SSG) |
| Language | TypeScript (strict mode) |
| State — local | useState, useReducer |
| State — global | Zustand / Redux Toolkit |
| State — server | TanStack Query |
| Forms | React Hook Form |
| Styling | CSS Modules / Tailwind CSS |
| Component docs | Storybook |
| Unit/integration tests | Vitest + React Testing Library |
| E2E tests | Playwright / Cypress |
| API mocking | MSW |
| Linting | ESLint + typescript-eslint |
| Formatting | Prettier |
| Security scanning | npm audit + Snyk |
| Performance profiling | React DevTools + Lighthouse |
| Bundle analysis | rollup-plugin-visualizer |

---

*This skill reflects senior-level production experience and research from the React ecosystem as of April 2026.*
