import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/date_formatter.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/request_details_viewmodel.dart';
import '../../viewmodels/requests_viewmodel.dart';
import '../resolution/completed_screen.dart';
import '../widgets/priority_chip.dart';
import '../widgets/status_chip.dart';
import '../widgets/status_timeline.dart';
import 'photo_viewer_screen.dart';

/// Frame 10: Request Details.
class RequestDetailsScreen extends StatefulWidget {
  final int requestId;

  const RequestDetailsScreen({super.key, required this.requestId});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestDetailsViewModel>().load(widget.requestId);
    });
  }

  // ---------------- Confirm Resolution ----------------

  Future<void> _onConfirmResolution(RequestDetailsViewModel vm) async {
    // true = fixed, false = still a problem, null = Back pressed
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.confirmResolution,
      arguments: widget.requestId,
    );

    if (result == null || !mounted) return; // nothing was answered

    // Home and My Requests show the new status too
    context.read<HomeViewModel>().refresh();
    context.read<RequestsViewModel>().refresh();

    // Reload this request, so the timeline includes the new entry
    await vm.refresh();
    if (!mounted) return;

    if (result == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompletedScreen(timeline: vm.timeline),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for letting us know. Your request has been reopened.'),
        ),
      );
    }
  }

  // ---------------- Delete (reported by mistake) ----------------

  Future<void> _onDelete(RequestDetailsViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this request?'),
        content: const Text(
            'Use this if you reported it by mistake. The request and its photos '
            'will be removed and maintenance will not see it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Grab these before the await (the screen closes afterwards)
    final home = context.read<HomeViewModel>();
    final requests = context.read<RequestsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final deleted = await vm.deleteRequest();

    if (deleted) {
      home.refresh();
      requests.refresh();
      messenger.showSnackBar(const SnackBar(content: Text('Request deleted.')));
      navigator.pop();
    } else if (vm.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
    }
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RequestDetailsViewModel>();
    final request = vm.request;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: _buildBody(vm),
      bottomNavigationBar: request == null ? null : _buildBottomButton(vm),
    );
  }

  Widget _buildBody(RequestDetailsViewModel vm) {
    final request = vm.request;

    // First load: spinner
    if (vm.isLoading && request == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.navy));
    }

    // Failed: message + retry
    if (request == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.errorMessage ?? 'Request not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.navy)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => vm.load(widget.requestId),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.navy,
      onRefresh: vm.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          // ---------- Photos ----------
          _PhotoCarousel(
            urls: vm.photoUrls,
            hasPhotos: request.photos.isNotEmpty,
          ),
          const SizedBox(height: 16),

          // ---------- Title + chips ----------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(request.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
              ),
              PriorityChip(priority: request.priority),
              const SizedBox(width: 6),
              StatusChip(status: request.status),
            ],
          ),
          const SizedBox(height: 12),

          // ---------- Details ----------
          _DetailRow(icon: Icons.info, label: 'Reference', value: '#${request.reference}'),
          _DetailRow(
              icon: Icons.calendar_today,
              label: 'Date Submitted',
              value: DateFormatter.withTime(request.dateSubmitted)),
          _DetailRow(icon: Icons.category, label: 'Category', value: request.category),
          _DetailRow(icon: Icons.apartment, label: 'Accommodation', value: vm.accommodationName),
          _DetailRow(icon: Icons.home, label: 'Room', value: vm.roomNumber),

          const Divider(height: 28, color: AppColors.navy),

          // ---------- Description ----------
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(left: 10),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.navy, width: 2)),
            ),
            child: Text(request.description, style: const TextStyle(color: AppColors.navy)),
          ),

          const Divider(height: 28, color: AppColors.navy),

          // ---------- Status Updates ----------
          Text('Status Updates', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          StatusTimeline(entries: vm.timeline, isFinished: vm.isClosed),
        ],
      ),
    );
  }

  /// Bottom button, depending on the request:
  /// Delete (untouched), Confirm Resolution (Completed), Completed label (Closed).
  Widget? _buildBottomButton(RequestDetailsViewModel vm) {
    Widget? button;

    if (vm.canDelete) {
      button = OutlinedButton.icon(
        onPressed: vm.isDeleting ? null : () => _onDelete(vm),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        icon: vm.isDeleting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger),
              )
            : const Icon(Icons.delete_outline),
        label: const Text('Delete request'),
      );
    } else if (vm.canConfirmResolution) {
      button = OutlinedButton(
        onPressed: () => _onConfirmResolution(vm),
        child: const Text('Confirm Resolution'),
      );
    } else if (vm.isClosed) {
      button = OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.navy, width: 1.5),
        ),
        child: const Text('Completed'),
      );
    }

    if (button == null) return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 8, 40, 16),
        child: button,
      ),
    );
  }
}

/// One details line: icon, label, value.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.navy),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: AppColors.navy, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Swipeable photos with dots and an expand button.
class _PhotoCarousel extends StatefulWidget {
  final List<String> urls;
  final bool hasPhotos;

  const _PhotoCarousel({required this.urls, required this.hasPhotos});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  int _page = 0;

  void _openViewer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(photoUrls: widget.urls, initialIndex: _page),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // No photos (or links failed): placeholder box
    if (widget.urls.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.navy, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography, size: 36, color: AppColors.navy),
            const SizedBox(height: 8),
            Text(
              widget.hasPhotos ? 'Photos could not be loaded' : 'No photos added',
              style: const TextStyle(color: AppColors.navy),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => GestureDetector(
                onTap: _openViewer,
                child: Image.network(
                  widget.urls[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator(color: AppColors.navy)),
                  errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image, size: 48, color: AppColors.navy)),
                ),
              ),
            ),

            // Expand icon (bottom right, as in the design)
            Positioned(
              right: 8,
              bottom: 8,
              child: GestureDetector(
                onTap: _openViewer,
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.open_in_full, size: 16, color: AppColors.white),
                ),
              ),
            ),

            // Dots when there is more than one photo
            if (widget.urls.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.urls.length; i++)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _page
                              ? AppColors.white
                              : AppColors.white.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}