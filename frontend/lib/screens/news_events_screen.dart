import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../widgets/skeleton.dart';

class NewsEventsScreen extends StatefulWidget {
  const NewsEventsScreen({super.key});

  @override
  State<NewsEventsScreen> createState() => _NewsEventsScreenState();
}

class _NewsEventsScreenState extends State<NewsEventsScreen> {
  void _showEventDetails(Event event) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Cover Image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                      ? Image.network(
                          event.imageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: AppTheme.primary.withOpacity(0.1),
                              child: const Icon(Icons.broken_image, size: 48, color: AppTheme.textSecondary),
                            );
                          },
                        )
                      : Container(
                          height: 200,
                          color: AppTheme.primary.withOpacity(0.1),
                          child: const Icon(Icons.broken_image, size: 48, color: AppTheme.textSecondary),
                        ),
                ),
                // Details Padded Area
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Location Badge
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.secondary),
                          const SizedBox(width: 6),
                          Text(
                            event.eventTime.isNotEmpty ? "${event.eventDate} • ${event.eventTime}" : event.eventDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    event.location.split(',')[0],
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Text(
                        event.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.border),
                      const SizedBox(height: 12),
                      // Location Details
                      Row(
                        children: [
                          const Icon(Icons.map_outlined, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Description
                      const Text(
                        "About the Event",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Close Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        title: const Text("News & Events"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Event>>(
        stream: EventService().streamAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonList();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  const Text(
                    "Something went wrong while loading news & events",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final newsEvents = snapshot.data ?? const <Event>[];

          return newsEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.newspaper, size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 10),
                      const Text(
                        "No news or events posted yet",
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await EventService().forceSyncAll();
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                  itemCount: newsEvents.length,
                  itemBuilder: (context, index) {
                    final event = newsEvents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Pefect sharp rectangular container box
                        side: const BorderSide(color: AppTheme.border, width: 1),
                      ),
                      elevation: 3,
                      shadowColor: Colors.black.withOpacity(0.18),
                      child: InkWell(
                        onTap: () => _showEventDetails(event),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Event Cover Image
                            (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                                ? Image.network(
                                    event.imageUrl!,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 160,
                                        color: AppTheme.primary.withOpacity(0.08),
                                        child: const Icon(Icons.newspaper_outlined, size: 40, color: AppTheme.textSecondary),
                                      );
                                    },
                                  )
                                : Container(
                                    height: 160,
                                    color: AppTheme.primary.withOpacity(0.08),
                                    child: const Icon(Icons.newspaper_outlined, size: 40, color: AppTheme.textSecondary),
                                  ),
                            // Event Text Details Area
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date & Location Info Row
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 12, color: AppTheme.secondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        event.eventTime.isNotEmpty ? "${event.eventDate} • ${event.eventTime}" : event.eventDate,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            const Icon(Icons.location_on, size: 12, color: AppTheme.textSecondary),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                event.location.split(',')[0],
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppTheme.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Event Title
                                  Text(
                                    event.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Event Short Description
                                  Text(
                                    event.description,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  // Read More Link Indicator
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: const [
                                      Text(
                                        "Read Details",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward, size: 12, color: AppTheme.primary),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AnimatedSkeleton(width: double.infinity, height: 160),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        AnimatedSkeleton(width: 80, height: 12),
                        AnimatedSkeleton(width: 80, height: 12),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const AnimatedSkeleton(width: double.infinity, height: 16),
                    const SizedBox(height: 8),
                    const AnimatedSkeleton(width: 200, height: 16),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedSkeleton(width: 80, height: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
