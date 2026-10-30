import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../viewmodels/requests_viewmodel.dart';
import '../widgets/request_card.dart';

/// Frame 8: My Requests tab.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false; // title row shows the search box instead

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestsViewModel>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _isSearching = true);

  void _closeSearch(RequestsViewModel vm) {
    _searchController.clear();
    vm.clearSearch();
    FocusScope.of(context).unfocus();
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RequestsViewModel>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- Title row / search box ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
            child: _isSearching
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: vm.setSearchQuery,
                          decoration: const InputDecoration(
                            hintText: 'Search title, category or MT number',
                            prefixIcon: Icon(Icons.search, color: AppColors.navy),
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.navy),
                        onPressed: () => _closeSearch(vm),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text('My Requests',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontSize: 20)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search,
                            color: AppColors.navy, size: 28),
                        onPressed: _openSearch,
                      ),
                    ],
                  ),
          ),

          // ---------- Filter chips ----------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final f in RequestFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterPill(
                      label: f.label,
                      isSelected: vm.filter == f,
                      onTap: () => vm.setFilter(f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---------- White panel with the list ----------
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: RefreshIndicator(
                color: AppColors.navy,
                onRefresh: vm.refresh,
                child: _buildList(vm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(RequestsViewModel vm) {
    // First load
    if (vm.isLoading && vm.visibleRequests.isEmpty && !vm.hasNoRequestsAtAll) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.navy));
    }

    // Error, nothing to show, or no matches: a message that can
    // still be pulled down to refresh
    final message = vm.errorMessage ??
        (vm.hasNoRequestsAtAll
            ? "You haven't reported any problems yet."
            : vm.visibleRequests.isEmpty
                ? 'No requests match.'
                : null);

    if (message != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.navy)),
            ),
          ),
        ],
      );
    }

    // The cards
    final requests = vm.visibleRequests;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => RequestCard(
        request: requests[i],
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.requestDetails,
          arguments: requests[i].id,
        ),
      ),
    );
  }
}

/// One filter chip: navy when selected, grey otherwise.
class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.white : AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}