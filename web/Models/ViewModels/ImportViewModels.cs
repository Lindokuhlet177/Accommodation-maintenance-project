namespace StudentStayFix.Web.Models.ViewModels;

/// <summary>One row from the uploaded list.</summary>
public class ImportRow
{
    public int Line { get; set; }
    public string Name { get; set; } = "";
    public string Surname { get; set; } = "";
    public string StudentNumber { get; set; } = "";
    public string RoomNumber { get; set; } = "";
    public string? Email { get; set; }
    public string? Phone { get; set; }

    /// <summary>Why this row can't be imported (null = ready).</summary>
    public string? Problem { get; set; }
    public bool IsReady => Problem == null;
    public string FullName => $"{Name} {Surname}".Trim();
}

public class ImportPreviewViewModel
{
    public string PropertyName { get; set; } = "";
    public string FileName { get; set; } = "";
    public List<ImportRow> Rows { get; set; } = [];

    /// <summary>The ready rows, carried to the Import button in a hidden field.</summary>
    public string ReadyRowsJson { get; set; } = "[]";

    public int ReadyCount => Rows.Count(r => r.IsReady);
    public int ProblemCount => Rows.Count(r => !r.IsReady);
}

/// <summary>One line of the result from import_tenancies.</summary>
public class ImportResult
{
    public int Line { get; set; }
    public string Outcome { get; set; } = "";   // "added" or "skipped"
    public string Message { get; set; } = "";
    public bool Linked { get; set; }
}

public class ImportSummaryViewModel
{
    public string PropertyName { get; set; } = "";
    public List<ImportResult> Results { get; set; } = [];
    public Dictionary<int, string> NamesByLine { get; set; } = [];

    public int Added => Results.Count(r => r.Outcome == "added");
    public int Linked => Results.Count(r => r.Linked);
    public int Skipped => Results.Count(r => r.Outcome != "added");
}