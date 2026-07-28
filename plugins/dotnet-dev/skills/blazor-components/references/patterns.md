# Blazor Component Patterns

Concrete shapes for the rules in `SKILL.md`. Adapt names to the project's conventions.

## Directory layout

| Directory | Holds |
|---|---|
| `Pages/` | Routable components (`@page`) |
| `Components/` | Reusable non-routable UI |
| `Shared/` | Layouts, navigation, app shell |

Use `.razor` for markup-led components; add a `.razor.cs` code-behind when the logic outgrows a `@code` block. Check the project's existing components before creating a new one — reuse beats reimplementation.

## MudBlazor form

```razor
<MudCard>
    <MudCardContent>
        <MudTextField @bind-Value="_model.Name"
                      Label="Name"
                      Required="true"
                      Variant="Variant.Outlined" />

        <MudSelect @bind-Value="_model.Category"
                   Label="Category"
                   Variant="Variant.Outlined">
            @foreach (var category in _categories)
            {
                <MudSelectItem Value="@category">@category</MudSelectItem>
            }
        </MudSelect>
    </MudCardContent>

    <MudCardActions>
        <MudButton Variant="Variant.Filled"
                   Color="Color.Primary"
                   OnClick="HandleSubmit">
            Submit
        </MudButton>
    </MudCardActions>
</MudCard>
```

## Validated form

`EditForm` + `DataAnnotationsValidator`, with `For` on each field so validation messages bind to the right property:

```razor
<EditForm Model="@_model" OnValidSubmit="HandleValidSubmitAsync">
    <DataAnnotationsValidator />

    <MudTextField @bind-Value="_model.Email"
                  Label="Email"
                  For="@(() => _model.Email)" />

    <MudButton ButtonType="ButtonType.Submit"
               Variant="Variant.Filled"
               Color="Color.Primary">
        Submit
    </MudButton>
</EditForm>
```

## Parent–child communication

```razor
@* Parent *@
<ChildComponent Value="@_currentValue" OnValueChanged="HandleValueChanged" />

@code {
    private string _currentValue = "";

    // No StateHasChanged() needed — EventCallback re-renders the parent.
    private void HandleValueChanged(string newValue) => _currentValue = newValue;
}
```

```razor
@* Child *@
@code {
    [Parameter] public string Value { get; set; } = "";
    [Parameter] public EventCallback<string> OnValueChanged { get; set; }

    private Task UpdateValue(string newValue) => OnValueChanged.InvokeAsync(newValue);
}
```

## Guarding parameter-change work

`OnParametersSetAsync` runs on every parent re-render, so compare before doing expensive work:

```csharp
private int? _loadedOrderId;

[Parameter] public int OrderId { get; set; }

protected override async Task OnParametersSetAsync()
{
    if (_loadedOrderId == OrderId)
    {
        return;
    }

    _loadedOrderId = OrderId;
    await LoadOrderAsync();
}
```

## Cascading values

```razor
<CascadingValue Value="@_userContext">
    <ChildComponents />
</CascadingValue>
```

```csharp
[CascadingParameter] public UserContext? UserContext { get; set; }
```

## Routing

```razor
@page "/users"
@page "/users/{UserId:int}"

@code {
    [Parameter] public int? UserId { get; set; }
}
```

Programmatic navigation through `NavigationManager`; links via `<MudLink>` or `<NavLink>`:

```razor
@inject NavigationManager Navigation

<MudButton OnClick="@(() => Navigation.NavigateTo("/dashboard"))">
    Go to Dashboard
</MudButton>
```

## Authorization

```razor
<AuthorizeView>
    <Authorized>
        <p>Welcome, @context.User.Identity?.Name!</p>
        <AuthorizeView Roles="Admin">
            <Authorized>
                <MudButton>Admin Actions</MudButton>
            </Authorized>
        </AuthorizeView>
    </Authorized>
    <NotAuthorized>
        <p>Please log in</p>
    </NotAuthorized>
</AuthorizeView>
```

`AuthorizeView` controls *rendering only*. It is not a security boundary — the API must independently authorize every request, because a client-side check is trivially bypassed. For permission-based (rather than role-based) checks, follow the project's authorization library.

## Loading and error handling

```razor
@inject ISnackbar Snackbar
@inject IMyApiClient ApiClient

@if (_isLoading)
{
    <MudProgressCircular Indeterminate="true" />
}
else
{
    <MudTable Items="@_items" />
}

@code {
    private bool _isLoading;

    private async Task SaveDataAsync()
    {
        _isLoading = true;
        try
        {
            await ApiClient.SaveAsync(_model);
            Snackbar.Add("Saved successfully", Severity.Success);
        }
        catch (HttpRequestException ex)
        {
            Logger.LogWarning(ex, "Save failed for {ItemId}", _model.Id);
            Snackbar.Add("Could not reach the server. Please try again.", Severity.Error);
        }
        finally
        {
            _isLoading = false;
        }
    }
}
```

Log the exception with context; show the user a readable message. Never put `ex.Message` in the snackbar.

## JS interop with cleanup

Interop setup belongs behind `firstRender`, and every reference it creates must be disposed:

```razor
@inject IJSRuntime JS
@implements IAsyncDisposable

@code {
    private DotNetObjectReference<MyComponent>? _selfRef;
    private IJSObjectReference? _module;

    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        if (!firstRender)
        {
            return;
        }

        _module = await JS.InvokeAsync<IJSObjectReference>("import", "./js/my-module.js");
        _selfRef = DotNetObjectReference.Create(this);
        await _module.InvokeVoidAsync("initialize", _selfRef);
    }

    [JSInvokable]
    public Task OnJsEvent(string payload)
    {
        // Called from JS — the renderer is not aware of it, so request a render.
        StateHasChanged();
        return Task.CompletedTask;
    }

    public async ValueTask DisposeAsync()
    {
        if (_module is not null)
        {
            await _module.InvokeVoidAsync("teardown");
            await _module.DisposeAsync();
        }

        _selfRef?.Dispose();
    }
}
```

## Testing

See `dotnet-dev:test-conventions` for BUnit conventions and examples — component tests follow the same rules as the rest of the suite.
