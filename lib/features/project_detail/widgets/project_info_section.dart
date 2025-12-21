import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vronmobile2/core/i18n/i18n_service.dart';
import 'package:vronmobile2/features/home/models/project.dart';

/// Widget displaying project information including description, subscription, and dates
class ProjectInfoSection extends StatelessWidget {
  final Project project;

  const ProjectInfoSection({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description Section
        _buildSectionTitle(context, 'projectDetail.description'.tr()),
        const SizedBox(height: 8),
        _buildDescription(context),

        const SizedBox(height: 24),

        // Subscription Section
        if (project.subscription != null) ...[
          _buildSectionTitle(context, 'projectDetail.subscription'.tr()),
          const SizedBox(height: 8),
          _buildSubscriptionInfo(context),
          const SizedBox(height: 24),
        ],

        // Last Updated Section
        if (project.liveDate != null) ...[_buildLastUpdated(context)],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDescription(BuildContext context) {
    if (project.description != null && project.description!.isNotEmpty) {
      return Text(
        project.description!,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    } else {
      return Text(
        'projectDetail.noDescription'.tr(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }
  }

  Widget _buildSubscriptionInfo(BuildContext context) {
    final subscription = project.subscription!;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: subscription.isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    subscription.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Trial Badge
                if (subscription.isTrial)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'projectDetail.trialStatus'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            if (subscription.price != null &&
                subscription.currency != null) ...[
              const SizedBox(height: 12),
              Text(
                '${subscription.currency} ${subscription.price?.toStringAsFixed(2)} / ${subscription.renewalInterval ?? 'month'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],

            if (subscription.renewsAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Renews: ${DateFormat.yMMMd().format(subscription.renewsAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context) {
    final dateStr = DateFormat.yMMMd().format(project.liveDate!);

    return Text(
      'projectDetail.lastUpdated'.tr(params: {'date': dateStr}),
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
    );
  }
}
