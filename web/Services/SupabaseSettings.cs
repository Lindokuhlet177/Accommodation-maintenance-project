namespace StudentStayFix.Web.Services;
/// The "Supabase" section of appsettings.json.

public class SupabaseSettings
{
    public string Url { get; set; } = "";
    public string PublishableKey { get; set; } = "";
    public string PhotoBucket { get; set; } = "request-photos";
}