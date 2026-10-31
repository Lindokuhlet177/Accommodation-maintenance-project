using StudentStayFix.Web.Services;
using Microsoft.AspNetCore.Authentication.Cookies;

var builder = WebApplication.CreateBuilder(args);

// MVC: controllers + views
builder.Services.AddControllersWithViews();

// Supabase settings from appsettings.json -> "Supabase"
builder.Services.Configure<SupabaseSettings>(builder.Configuration.GetSection("Supabase"));

// Supabase Auth service (gets its own HttpClient)
builder.Services.AddHttpClient<SupabaseAuth>();

// Lets services read the logged-in user's token
builder.Services.AddHttpContextAccessor();

// Supabase database service (tables, functions, photo links)
builder.Services.AddHttpClient<SupabaseDb>();
builder.Services.AddScoped<PropertyContext>();

// Cookie login: after Supabase accepts the password we remember who the user is
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(o =>
    {
        o.LoginPath = "/Account/Login";
        o.LogoutPath = "/Account/Logout";
        o.AccessDeniedPath = "/Account/AccessDenied";
        o.ExpireTimeSpan = TimeSpan.FromHours(8);
        o.SlidingExpiration = true;
        o.Cookie.Name = "ssf_auth";
        o.Cookie.HttpOnly = true;                              // JavaScript can't read it
        o.Cookie.SecurePolicy = CookieSecurePolicy.Always;      // HTTPS only
        o.Cookie.SameSite = SameSiteMode.Lax;
    });

// Who may open which pages
builder.Services.AddAuthorization(o =>
{
    o.AddPolicy("Staff", p => p.RequireRole("Landlord", "Caretaker"));
    o.AddPolicy("LandlordOnly", p => p.RequireRole("Landlord"));
});

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Account/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();
app.UseAuthentication();
app.UseMiddleware<TokenRefreshMiddleware>();   // keeps the Supabase token fresh
app.UseAuthorization();

app.MapStaticAssets();


// The site opens on the Login page
app.MapControllerRoute(
        name: "default",
        pattern: "{controller=Account}/{action=Login}/{id?}")
    .WithStaticAssets();

app.Run();