---
name: blazor-components
description: Use when building or modifying Blazor components, pages, layouts, or client-side services — especially with MudBlazor. Covers the lifecycle traps that cause duplicate initialization and WASM memory leaks, MudBlazor-over-HTML rules, and state ownership. Load before editing a .razor file. For component tests, see dotnet-dev:test-conventions.
---

# Blazor + MudBlazor Components

Check the project's CLAUDE.md for its typed HTTP clients, auth library, theme class, feature-flag service, directory conventions, and BFF/anti-forgery setup before writing anything.

Code examples for each area below live in `references/patterns.md` — read it when you need the concrete shape rather than the rule.

## Lifecycle traps

These four cause most real Blazor bugs and are not obvious from the API surface:

* **`OnParametersSetAsync` fires on every parent re-render**, not only when a parameter value actually changed. Expensive work here — an API call, a recomputation — runs far more often than intended. Guard it with a value comparison against the previous parameter or an explicit dirty flag.
* **`OnAfterRenderAsync` receives `firstRender` for a reason.** One-time setup, above all JS interop initialization, must sit inside `if (firstRender)`. Without the guard it re-runs on every render, producing duplicate event listeners and duplicate observers.
* **`Dispose` is called synchronously by the renderer.** Never write `async void Dispose()` — its exceptions are unobservable and its work may not finish. Implement `IAsyncDisposable`/`DisposeAsync` when teardown is genuinely async.
* **Un-disposed subscriptions leak for the lifetime of the tab.** Event handlers, timers, `CancellationTokenSource`, `DotNetObjectReference`, and `NavigationManager.LocationChanged` handlers all need explicit cleanup. In a long-running WASM session there is no process recycle to save you.

Use `OnInitialized`/`OnInitializedAsync` for setup that depends only on injected services, `OnParametersSet` for work that depends on parameters.

## MudBlazor is the component vocabulary

**Use MudBlazor components instead of raw HTML wherever one exists** — `MudButton`, `MudTextField`, `MudSelect`, `MudTable`, `MudDialog`. Mixing raw HTML with MudBlazor produces inconsistent theming, spacing, and focus behavior that is tedious to unpick later. Do not introduce a second UI library alongside it.

* Colors via `Color.Primary`/`Color.Secondary`, not hex literals. If the project defines a theme class, use its constants.
* Spacing via MudBlazor utility classes: `Class="ma-4"`, `Class="pa-2"`.
* Dialogs, snackbars, and overlays via the injected services `IDialogService` and `ISnackbar` — not hand-rolled markup.
* For component parameters and examples, query current MudBlazor documentation through whichever documentation tool the session has available (`context7` resolves `MudBlazor`). Do not guess parameter names from memory; MudBlazor's API changes across major versions.

## State ownership

Private fields with a leading underscore for component-local state: `_isLoading`, `_model`.

Communication follows one direction per mechanism:

* **Parent → child**: `[Parameter]` properties.
* **Child → parent**: `EventCallback<T>`. It marshals to the parent's synchronization context and triggers its re-render automatically — a plain `Action` does neither.
* **Sibling → sibling**: lift the state into the common parent, or a scoped service raising an event. Never reach across the tree directly.
* **Ambient values** (theme, user context): `[CascadingParameter]`, and only for values genuinely needed by many descendants.

`StateHasChanged()` is needed after mutations the framework can't observe — a callback from a timer, a JS interop invocation, or a subscribed service event. Calling it at the end of an ordinary awaited event handler is redundant; the renderer already re-renders after those.

## API calls

Inject the project's typed client (`@inject IMyApiClient ApiClient`), not raw `HttpClient`.

Every call gets: `_isLoading = true` before, reset in `finally`, a `catch (HttpRequestException)` surfacing a user-readable message through `ISnackbar`, and a rendered loading state so the UI is never silently inert. Never surface a raw exception message to the user.

## Rendering performance

* `@key` on every element in a rendered list, keyed by stable identity — without it, Blazor's diff can reuse the wrong element and carry over form state.
* `Virtualize` for long lists; pagination for large data sets.
* `ShouldRender()` only after measuring an actual problem — a wrong override silently freezes the component.

## Accessibility

`aria-label` on every icon-only button — an icon has no accessible name. Keyboard navigation and focus order must work without a mouse. Use semantic elements for headings and landmarks even inside MudBlazor layouts, and verify contrast against the theme rather than assuming defaults pass.
