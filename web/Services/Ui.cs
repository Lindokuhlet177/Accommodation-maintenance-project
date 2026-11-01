namespace StudentStayFix.Web.Services;

/// <summary>Display helpers shared by the pages.</summary>
public static class Ui
{
    private static readonly TimeZoneInfo SouthAfrica = FindSouthAfrica();

    /// <summary>Current time in South Africa, whatever the server's time zone.</summary>
    public static DateTime Now => TimeZoneInfo.ConvertTime(DateTime.UtcNow, SouthAfrica);

    /// <summary>"Monday, 21 September 2025"</summary>
    public static string TodayText => Now.ToString("dddd, d MMMM yyyy");

    /// <summary>"Good morning" / "Good afternoon" / "Good evening"</summary>
    public static string Greeting => Now.Hour switch
    {
        < 12 => "Good morning",
        < 17 => "Good afternoon",
        _ => "Good evening"
    };

    /// <summary>Converts a database time (UTC) to South African time.</summary>
    public static DateTime Local(DateTimeOffset value) =>
        TimeZoneInfo.ConvertTime(value, SouthAfrica).DateTime;
    /// <summary>Cuts long text: "The tap in the bathroom is…"</summary>
    public static string Shorten(string? text, int max)
    {
        if (string.IsNullOrWhiteSpace(text)) return "";
        text = text.Trim();
        return text.Length <= max ? text : text[..max].TrimEnd() + "…";
    }

    /// <summary>"Today 10:00", "Tomorrow 09:30" or "Thu 24 Sep 14:00".</summary>
    public static string When(DateTime local)
    {
        var today = Now.Date;
        var day = local.Date == today ? "Today"
                : local.Date == today.AddDays(1) ? "Tomorrow"
                : local.ToString("ddd d MMM");
        return $"{day} {local:HH:mm}";
    }
    /// <summary>"Just now", "5 min ago", "2 hours ago", "Yesterday", or a date.</summary>
    public static string Ago(DateTimeOffset value)
    {
        var diff = DateTimeOffset.UtcNow - value;
        if (diff.TotalMinutes < 1) return "Just now";
        if (diff.TotalMinutes < 60) return $"{(int)diff.TotalMinutes} min ago";
        if (diff.TotalHours < 24) return $"{(int)diff.TotalHours} hour{((int)diff.TotalHours == 1 ? "" : "s")} ago";
        if (diff.TotalDays < 2) return "Yesterday";
        return Local(value).ToString("d MMM yyyy");
    }

    /// <summary>Icon for each request category (Bootstrap Icons).</summary>
    public static string CategoryIcon(string? category) => category switch
    {
        "Plumbing" => "bi-droplet-fill",
        "Electrical" => "bi-lightning-charge-fill",
        "Furniture" => "bi-lamp-fill",
        "Appliances" => "bi-plug-fill",
        "Doors & Windows" => "bi-door-closed-fill",
        _ => "bi-tools"
    };

    /// <summary>Soft background colour for the category icon square.</summary>
    public static string CategoryCss(string? category) => category switch
    {
        "Plumbing" => "cat-blue",
        "Electrical" => "cat-yellow",
        "Furniture" => "cat-purple",
        "Appliances" => "cat-teal",
        "Doors & Windows" => "cat-grey",
        _ => "cat-grey"
    };

    private static TimeZoneInfo FindSouthAfrica()
    {
        try { return TimeZoneInfo.FindSystemTimeZoneById("Africa/Johannesburg"); }
        catch (TimeZoneNotFoundException) { }
        try { return TimeZoneInfo.FindSystemTimeZoneById("South Africa Standard Time"); }
        catch (TimeZoneNotFoundException) { }
        return TimeZoneInfo.Utc;
    }
}
