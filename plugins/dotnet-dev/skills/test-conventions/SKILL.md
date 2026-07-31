---
name: test-conventions
description: Use when writing, modifying, or extending xUnit tests, BUnit component tests, or test doubles in a .NET project — covers test naming, assertion library, mocking, and structure rules that differ from common defaults. Load before writing the first test, including a single test added alongside a feature. Not for judging whether an existing PR's test coverage is adequate.
---

# .NET Test Conventions

These rules override habits carried in from other codebases. Check the project's CLAUDE.md first — a project-level convention wins over anything here.

## Stack

| Concern | Use | Notes |
|---|---|---|
| Framework | xUnit | |
| Assertions | Shouldly | `result.ShouldBe(expected)`, not `Assert.Equal` |
| Components | BUnit | Blazor render + interaction tests |
| Mocking | Moq | NSubstitute is fine to *propose*, but it needs a new dependency — ask first |

## Structure rules

**No `// Arrange`, `// Act`, `// Assert` comments.** They restate what the code already shows. Separate the phases with a blank line if the test is long enough to need it.

Name tests `MethodName_StateUnderTest_ExpectedBehavior`:

```csharp
[Fact]
public async Task GetOrder_WhenOrderMissing_ReturnsNotFound()
```

Group related tests in nested classes named after the member under test:

```csharp
public class OrderServiceTests
{
    public class GetOrder
    {
        [Fact]
        public async Task WhenOrderMissing_ReturnsNotFound() { }
    }
}
```

One behavior per test. A test that asserts four unrelated things fails without telling you which behavior broke.

## What makes a test worth having

Test observable behavior through the public surface. A test that asserts on a private field, a call count that no caller depends on, or the exact order of two independent operations will break on every harmless refactor while catching nothing.

Cover, in this order of value:

1. Every branch of conditional logic — including the `else` nobody wrote a test for.
2. Boundaries: empty collection, single element, null, zero, max value, off-by-one around any comparison.
3. Failure paths: the exception, the timeout, the not-found, the permission denial.
4. The happy path.

Coverage percentage is a diagnostic, not a goal. 100% coverage of getters proves nothing; one test of the retry path is worth fifty of them.

## Isolation

Tests must pass in any order and in parallel. Shared mutable state — a static field, a real database, a file on disk, `DateTime.Now` — is what makes a suite flaky. Inject a clock rather than reading the ambient one.

Mock at the boundary you own: your repository interface, not EF Core's internals. Use realistic test data; `"foo"` in an email field hides format bugs.

## BUnit component tests

Verify rendered output, user interaction, and `EventCallback` invocation — not internal component state.

```csharp
[Fact]
public void OrderRow_WhenCancelClicked_InvokesCallback()
{
    using var ctx = new TestContext();
    ctx.Services.AddSingleton<IOrderService>(Mock.Of<IOrderService>());
    var invoked = false;

    var cut = ctx.RenderComponent<OrderRow>(p => p
        .Add(c => c.OrderId, 42)
        .Add(c => c.OnCancelled, () => { invoked = true; }));

    cut.Find("button[aria-label='Cancel']").Click();

    invoked.ShouldBeTrue();
}
```

Register a double for every injected service — MudBlazor components need `ctx.Services.AddMudServices()` before they will render. Select elements by role or `aria-label` rather than by CSS class, so a styling change doesn't break the test.
