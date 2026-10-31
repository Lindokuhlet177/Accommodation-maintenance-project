using System.Globalization;

namespace StudentStayFix.Web.Models.ViewModels;

/// <summary>One coloured part of the Request Status donut.</summary>
public record ChartSlice(string Label, int Count, string Color);

/// <summary>One line of the Priority Breakdown.</summary>
public record PriorityRow(string Label, int Count, int Percent, string CssClass);

public class DashboardViewModel
{
    public bool HasProperty { get; set; }
    public bool CanManageTasks { get; set; }

    // Stat cards
    public int OpenCount { get; set; }
    public int NewSinceYesterday { get; set; }
    public int UrgentCount { get; set; }
    public int InProgressCount { get; set; }

    // Request Status donut
    public int Total { get; set; }
    public List<ChartSlice> StatusSlices { get; set; } = [];

    // Priority Breakdown (active requests)
    public List<PriorityRow> Priorities { get; set; } = [];

    // Tables and lists
    public List<MaintenanceRequest> OpenRequests { get; set; } = [];
    public List<UpcomingTask> Tasks { get; set; } = [];
    public TaskForm NewTask { get; set; } = new();

    /// <summary>CSS conic-gradient for the donut, e.g. "#2F6FDE 0% 40%, ..."</summary>
    public string DonutGradient
    {
        get
        {
            if (Total == 0) return "#E2E8F0 0% 100%";   // grey ring when empty

            var parts = new List<string>();
            double start = 0;
            foreach (var s in StatusSlices.Where(s => s.Count > 0))
            {
                var end = start + s.Count * 100.0 / Total;
                // InvariantCulture: always "40.5", never "40,5" (CSS needs a dot)
                parts.Add(string.Create(CultureInfo.InvariantCulture,
                    $"{s.Color} {start:0.##}% {end:0.##}%"));
                start = end;
            }
            return string.Join(", ", parts);
        }
    }

    /// <summary>Works out every number on the Overview from the property's requests.</summary>
    public static DashboardViewModel Build(
        List<MaintenanceRequest> all, List<UpcomingTask> tasks, bool canManageTasks)
    {
        var active = all.Where(r => r.IsActive).ToList();
        var since = DateTimeOffset.UtcNow.AddDays(-1);

        var vm = new DashboardViewModel
        {
            HasProperty = true,
            CanManageTasks = canManageTasks,

            OpenCount = all.Count(r => r.Status is RequestStatus.Open or RequestStatus.Assigned),
            NewSinceYesterday = all.Count(r => r.DateSubmitted >= since),
            UrgentCount = active.Count(r => r.Priority == RequestPriority.Urgent),
            InProgressCount = all.Count(r => r.Status == RequestStatus.InProgress),

            Total = all.Count,
            OpenRequests = active.Take(6).ToList(),   // newest first (query order)
            Tasks = tasks
        };

        vm.StatusSlices =
        [
            new("Open", vm.OpenCount, "#2F6FDE"),
            new("In Progress", vm.InProgressCount, "#7FB2F0"),
            new("Awaiting student", all.Count(r => r.Status == RequestStatus.Completed), "#F59E0B"),
            new("Resolved", all.Count(r => r.Status == RequestStatus.Closed), "#22C55E")
        ];

        vm.Priorities = RequestPriority.All
            .Select(p =>
            {
                var count = active.Count(r => r.Priority == p);
                var percent = active.Count == 0 ? 0 : (int)Math.Round(count * 100.0 / active.Count);
                return new PriorityRow(p, count, percent, RequestPriority.Css(p));
            })
            .ToList();

        return vm;
    }
}