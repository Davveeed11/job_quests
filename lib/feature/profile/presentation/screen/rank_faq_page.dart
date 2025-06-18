import 'package:flutter/material.dart';
import 'package:my_job_quest/feature/splashscreen/domain/rank_dart.dart'; // Ensure this path is correct

class RankFaqPage extends StatelessWidget {
  final List<RankData>? ranks;

  const RankFaqPage({super.key, this.ranks});

  // Helper to format prices consistently
  String _formatPrice(int price) {
    if (price >= 1000000) {
      return '₦${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '₦${(price / 1000).toStringAsFixed(0)}K';
    }
    return '₦$price';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    // final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Understanding Ranks & FAQ',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        iconTheme: IconThemeData(color: textColor), // Set back button color
        elevation: 1, // Subtle shadow for the app bar
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface.withOpacity(0.5),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Explore the different Job Quest ranks and what they mean for your career.',
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Job Quest Ranks Explained'),
            const SizedBox(height: 12),
            ...ranks!.map((rank) => _buildRankFaqTile(context, rank)),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'General Questions'),
            const SizedBox(height: 12),
            _buildGeneralFaqTile(
              context,
              'How are ranks determined?',
              'Your rank is determined by a combination of your skills, experience, project complexity, and peer evaluations within the Job Quest platform.',
            ),
            _buildGeneralFaqTile(
              context,
              'Can my rank change over time?',
              'Yes, your rank is dynamic! As you complete more jobs, gain new skills, and receive positive feedback, your rank can increase. Inactive periods or negative feedback might lead to a reassessment.',
            ),
            _buildGeneralFaqTile(
              context,
              'What are the benefits of a higher rank?',
              'Higher ranks unlock access to more challenging and higher-paying jobs. They also indicate a higher level of trust and expertise to potential employers.',
            ),
            _buildGeneralFaqTile(
              context,
              'How do I improve my rank?',
              'Focus on taking on challenging projects, consistently delivering high-quality work, actively seeking feedback, and continuously learning new skills relevant to your field.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onBackground,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildRankFaqTile(BuildContext context, RankData rank) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Theme(
        // Override the default expansion tile theme to use rank color
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: rank.color,
          iconColor: rank.color,
          leading: Icon(rank.icon, color: rank.color, size: 30),
          title: Text(
            '${rank.rank} - ${rank.title} (${rank.subtitle})',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rank.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analogy: "${rank.analogy}"',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: rank.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Estimated Price Range: ${_formatPrice(rank.basePrice)} - ${_formatPrice(rank.maxPrice)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralFaqTile(
    BuildContext context,
    String question,
    String answer,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
