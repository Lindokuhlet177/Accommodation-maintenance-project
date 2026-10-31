using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using StudentStayFix.Web.Models;
using StudentStayFix.Web.Models.ViewModels;
using StudentStayFix.Web.Services;

namespace StudentStayFix.Web.Controllers;

public class AccountController : Controller
{
    private readonly SupabaseAuth _auth;
    private readonly SupabaseDb _db;

    public AccountController(SupabaseAuth auth, SupabaseDb db)
    {
        _auth = auth;
        _db = db;
    }

    // ---------------- LOGIN ----------------

    [HttpGet]
    public IActionResult Login(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true)
            return RedirectToAction("Index", "Dashboard");

        return View(new LoginViewModel { ReturnUrl = returnUrl });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        // 1. Supabase checks the email + password
        AuthSession session;
        try
        {
            session = await _auth.SignInAsync(model.Email.Trim(), model.Password);
        }
        catch (SupabaseException ex)
        {
            ModelState.AddModelError("", ex.Message);
            return View(model);
        }

        // 2. Find them in the staff table, using THEIR token (RLS: own row only)
        Staff? staff;
        try
        {
            staff = await _db.GetOneAsync<Staff>(
                $"staff?select=*&id=eq.{session.UserId}", session.AccessToken);
        }
        catch (SupabaseException ex)
        {
            await _auth.SignOutAsync(session.AccessToken);
            ModelState.AddModelError("", "Could not load your account: " + ex.Message);
            return View(model);
        }

        // 3. Only approved landlords and caretakers with a building may continue
        var problem = staff switch
        {
            null => "This account is not registered as a landlord or caretaker.",
            _ when !string.Equals(staff.Role, model.Role, StringComparison.OrdinalIgnoreCase) =>
                $"This account is not registered as a {model.Role.ToLower()}. Please choose the correct role.",
            { IsApproved: false, Role: "Landlord" } =>
    "This landlord account is not active. Please contact the system administrator.",
            { IsApproved: false } => "Your caretaker account is waiting for the landlord's approval.",
            _ => null
        };
        if (problem != null)
        {
            await _auth.SignOutAsync(session.AccessToken);
            ModelState.AddModelError("", problem);
            return View(model);
        }

        // 4. Remember who they are in the encrypted login cookie
        var claims = AppClaims.Build(
     staff!.Id.ToString(), staff.Name, staff.Email, staff.Role,
     staff.Role == "Caretaker" ? staff.AccommodationId : null,
     staff.AvatarPath,
     session);

        var principal = new ClaimsPrincipal(
            new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme));
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);

        // Back to the page they wanted, but only if it's inside our site
        if (!string.IsNullOrEmpty(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
            return LocalRedirect(model.ReturnUrl);

        return RedirectToAction("Index", "Dashboard");
    }

    // ---------------- LOGOUT ----------------

    [HttpPost]
    [ValidateAntiForgeryToken]
    [Authorize]
    public async Task<IActionResult> Logout()
    {
        var token = User.FindFirst(AppClaims.AccessToken)?.Value;
        if (token != null) await _auth.SignOutAsync(token);

        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction(nameof(Login));
    }

    // ---------------- CARETAKER SIGN-UP ----------------

    [HttpGet]
    public async Task<IActionResult> Register()
    {
        if (User.Identity?.IsAuthenticated == true)
            return RedirectToAction("Index", "Dashboard");

        var model = new RegisterViewModel();
        await LoadAccommodationsAsync(model);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Register(RegisterViewModel model)
    {
        if (!ModelState.IsValid)
        {
            await LoadAccommodationsAsync(model);
            return View(model);
        }

        try
        {
            // The handle_new_caretaker trigger (Step W1) reads this metadata
            // and creates a PENDING staff row
            var signedInNow = await _auth.SignUpAsync(model.Email.Trim(), model.Password, new
            {
                account_type = "caretaker",
                name = model.Name.Trim(),
                accommodation_id = model.AccommodationId!.Value.ToString()
            });

            // If Supabase signed them in straight away, end that session:
            // they may only sign in once the landlord has approved them
            TempData["Success"] = signedInNow
                ? "Account created. The landlord must approve it before you can sign in."
                : "Account created. Confirm your email address, then wait for the landlord to approve your account.";

            return RedirectToAction(nameof(Login));
        }
        catch (SupabaseException ex)
        {
            ModelState.AddModelError("", ex.Message);
            await LoadAccommodationsAsync(model);
            return View(model);
        }
    }

    /// <summary>Fills the accommodation dropdown (works before login).</summary>
    private async Task LoadAccommodationsAsync(RegisterViewModel model)
    {
        try
        {
            model.Accommodations =
                await _db.RpcAsync<List<AccommodationOption>>("public_accommodations") ?? [];
        }
        catch (SupabaseException)
        {
            model.Accommodations = [];
            ModelState.AddModelError("", "Could not load the accommodation list. Please try again.");
        }
    }
    // ---------------- FORGOT / RESET PASSWORD ----------------

    [HttpGet]
    public IActionResult ForgotPassword() => View(new ForgotPasswordViewModel());

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        try
        {
            await _auth.SendPasswordResetAsync(model.Email.Trim());
        }
        catch (SupabaseException ex) when (ex.StatusCode == 429)
        {
            ModelState.AddModelError("", ex.Message);   // "Too many attempts…"
            return View(model);
        }
        catch (SupabaseException)
        {
            // Don't reveal whether the email has an account: carry on as normal
        }

        TempData["Success"] = "If an account exists for that email, we've sent a reset code.";
        return RedirectToAction(nameof(ResetPassword), new { email = model.Email.Trim() });
    }

    [HttpGet]
    public IActionResult ResetPassword(string? email = null) =>
        View(new ResetPasswordViewModel { Email = email ?? "" });

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ResetPassword(ResetPasswordViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        try
        {
            // 1. Check the code: gives a short session for this account only
            var session = await _auth.VerifyRecoveryCodeAsync(model.Email.Trim(), model.Code.Trim());

            // 2. Set the new password with that session, then end it
            await _auth.UpdatePasswordAsync(session.AccessToken, model.Password);
            await _auth.SignOutAsync(session.AccessToken);
        }
        catch (SupabaseException ex)
        {
            ModelState.AddModelError("", ex.Message);
            return View(model);
        }

        TempData["Success"] = "Password changed. Sign in with your new password.";
        return RedirectToAction(nameof(Login));
    }
    // ---------------- OTHER ----------------

    [HttpGet]
    public IActionResult AccessDenied() => View();

    public IActionResult Error() => View();
}