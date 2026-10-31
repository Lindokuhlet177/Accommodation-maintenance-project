using System.Text;

namespace StudentStayFix.Web.Services;

/// <summary>
/// Reads a CSV file into rows. Handles quotes ("Nkosi, Jr"), comma or
/// semicolon separators (Excel in South Africa often uses ;), and blank lines.
/// </summary>
public static class CsvReader
{
    public record CsvRow(int Line, string[] Fields);

    public static List<CsvRow> Parse(string text)
    {
        text = text.TrimStart('\uFEFF');   // remove Excel's invisible "BOM" character

        // Use whichever separator appears more in the first line
        var firstLine = text.Split('\n')[0];
        var sep = firstLine.Count(c => c == ';') > firstLine.Count(c => c == ',') ? ';' : ',';

        var rows = new List<CsvRow>();
        var row = new List<string>();
        var field = new StringBuilder();
        var inQuotes = false;
        var line = 1;
        var rowStart = 1;

        for (var i = 0; i < text.Length; i++)
        {
            var c = text[i];

            if (inQuotes)
            {
                if (c == '"' && i + 1 < text.Length && text[i + 1] == '"') { field.Append('"'); i++; }  // "" = a quote
                else if (c == '"') inQuotes = false;
                else { if (c == '\n') line++; field.Append(c); }
            }
            else if (c == '"') inQuotes = true;
            else if (c == sep) { row.Add(field.ToString()); field.Clear(); }
            else if (c == '\r') { /* ignore */ }
            else if (c == '\n')
            {
                row.Add(field.ToString()); field.Clear();
                rows.Add(new CsvRow(rowStart, row.ToArray())); row.Clear();
                line++;
                rowStart = line;
            }
            else field.Append(c);
        }

        if (field.Length > 0 || row.Count > 0)
        {
            row.Add(field.ToString());
            rows.Add(new CsvRow(rowStart, row.ToArray()));
        }

        // Drop completely empty lines
        return rows.Where(r => r.Fields.Any(f => !string.IsNullOrWhiteSpace(f))).ToList();
    }

    /// <summary>Position of a column, matching names loosely ("Student Nr" = "student_number").</summary>
    public static int FindColumn(string[] header, params string[] names)
    {
        static string Norm(string s) => new string(s.ToLowerInvariant().Where(char.IsLetterOrDigit).ToArray());
        var wanted = names.Select(Norm).ToHashSet();
        return Array.FindIndex(header, h => wanted.Contains(Norm(h)));
    }
}