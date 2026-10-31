using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using StudentStayFix.Web.Services;
using System.Security.Claims;

namespace StudentStayFix.Web.Controllers;

/// <summary>
/// Base class for every staff page. Before each action it loads the sidebar/header
/// data (Shell), so pages always know the user and the selected property.
/// </summary>
[Authorize(Policy = "Staff")]
public abstract class AppController : Controller
{
    protected readonly SupabaseDb Db;
    private readonly PropertyContext _property;

    protected ShellModel Shell { get; private set; } = new();

    protected AppController(SupabaseDb db, PropertyContext property)
    {
        Db = db;
        _property = property;
    }

    public override async Task OnActionExecutionAsync(
        ActionExecutingContext context, ActionExecutionDelegate next)
    {
        try
        {
            Shell = await _property.LoadAsync();
        }
        catch (SupabaseException ex) when (ex.StatusCode == 401)
        {
            // Token no longer valid: sign out and go to Login
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            context.Result = RedirectToAction("Login", "Account");
            return;
        }

        ViewData["Shell"] = Shell;
        await next();
    }

    /// <summary>The property shown in the sidebar.</summary>
    protected long? CurrentAccommodationId => Shell.Current?.Id;

    /// <summary>Is this property one the user may see?</summary>
    protected bool CanSee(long? accommodationId) =>
        accommodationId != null && Shell.Properties.Any(p => p.Id == accommodationId);
    /// <summary>Replaces one value in the login cookie (e.g. new name or photo).</summary>
    protected async Task UpdateCookieClaimAsync(string type, string? value)
    {
        var claims = User.Claims.Where(c => c.Type != type).ToList();
        claims.Add(new Claim(type, value ?? ""));

        var principal = new ClaimsPrincipal(
            new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme));
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);
    }
}