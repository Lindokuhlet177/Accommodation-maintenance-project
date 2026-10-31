using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using StudentStayFix.Web.Models;

namespace StudentStayFix.Web.Services;

/// <summary>
/// Supabase tokens last about an hour; our cookie lasts 8 hours.
/// Before each page request we renew the token if it's about to expire,
/// and re-check that the person is still approved staff.
/// </summary>
public class TokenRefreshMiddleware
{
    /// <summary>Renew when fewer than this many seconds are left.</summary>
    private const int RefreshWhenSecondsLeft = 120;

    private readonly RequestDelegate _next;

    public TokenRefreshMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context, SupabaseAuth auth, SupabaseDb db)
    {
        if (ShouldRefresh(context))
            await RefreshAsync(context, auth, db);

        await _next(context);
    }

    private static bool ShouldRefresh(HttpContext context)
    {
        if (context.User.Identity?.IsAuthenticated != true) return false;

        // Skip CSS, JS, images: pages only (they have no file extension)
        if (Path.HasExtension(context.Request.Path.Value)) return false;

        var expiresAt = context.User.FindFirst(AppClaims.ExpiresAt)?.Value;
        if (!long.TryParse(expiresAt, out var expires)) return true;

        var secondsLeft = expires - DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        return secondsLeft < RefreshWhenSecondsLeft;
    }

    private static async Task RefreshAsync(HttpContext context, SupabaseAuth auth, SupabaseDb db)
    {
        try
        {
            // 1. New tokens from Supabase
            var refreshToken = context.User.FindFirst(AppClaims.RefreshToken)?.Value ?? "";
            var session = await auth.RefreshAsync(refreshToken);

            // 2. Still approved staff?
            var staff = await db.GetOneAsync<Staff>(
                $"staff?select=*&id=eq.{session.UserId}", session.AccessToken);

            if (staff is null || !staff.IsApproved)
                throw new SupabaseException("Staff access has been removed.");

            // 3. Rewrite the cookie with the new tokens (and any name/role change)
            var claims = AppClaims.Build(
     staff.Id.ToString(), staff.Name, staff.Email, staff.Role,
     staff.Role == "Caretaker" ? staff.AccommodationId : null,
     staff.AvatarPath,
     session);

            var principal = new ClaimsPrincipal(
                new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme));

            await context.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);
            context.User = principal;   // this request uses the new token straight away
        }
        catch (SupabaseException)
        {
            // Refresh failed or access removed: sign out.
            // Protected pages will then send them to Login.
            await context.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            context.User = new ClaimsPrincipal(new ClaimsIdentity());
        }
    }
}