import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../services/rss_service.dart';

final _podcastFeedsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('podcast_feeds')
      .snapshots()
      .map((snap) => snap.docs
          .map<Map<String, dynamic>>(
            (d) => <String, dynamic>{'id': d.id, ...d.data()},
          )
          .toList());
});

final _rssFeedEpisodesProvider =
    FutureProvider.family<List<RssEpisode>, String>((ref, url) async {
  return RssService().fetchFeed(url);
});

class PodcastManagerScreen extends ConsumerStatefulWidget {
  const PodcastManagerScreen({super.key});

  @override
  ConsumerState<PodcastManagerScreen> createState() =>
      _PodcastManagerScreenState();
}

class _PodcastManagerScreenState extends ConsumerState<PodcastManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('Podcast Manager'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'RSS Feeds'),
            Tab(text: 'Uploaded'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _RssFeedsTab(),
          _UploadedTab(),
        ],
      ),
    );
  }
}

// ── RSS Feeds tab ────────────────────────────────────────────────────────────

class _RssFeedsTab extends ConsumerStatefulWidget {
  const _RssFeedsTab();

  @override
  ConsumerState<_RssFeedsTab> createState() => _RssFeedsTabState();
}

class _RssFeedsTabState extends ConsumerState<_RssFeedsTab> {
  final _urlCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addFeed() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid http(s) URL'),
        backgroundColor: AppColors.errorRed,
      ));
      return;
    }
    setState(() => _adding = true);
    try {
      await FirebaseFirestore.instance.collection('podcast_feeds').add({
        'url': url,
        'name': _nameCtrl.text.trim().isEmpty ? url : _nameCtrl.text.trim(),
        'isActive': true,
        'addedAt': FieldValue.serverTimestamp(),
      });
      _urlCtrl.clear();
      _nameCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('RSS feed added'),
          backgroundColor: AppColors.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedsAsync = ref.watch(_podcastFeedsProvider);

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.p16),
      children: [
        // Add feed form
        Container(
          padding: const EdgeInsets.all(AppDimensions.p16),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(AppDimensions.r12),
            border: Border.all(color: AppColors.border1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ADD RSS FEED', style: AppTextStyles.label),
              const SizedBox(height: AppDimensions.p12),
              TextField(
                controller: _nameCtrl,
                style: AppTextStyles.body,
                decoration: const InputDecoration(
                  labelText: 'Feed name (optional)',
                  filled: true,
                  fillColor: AppColors.bg3,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _urlCtrl,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.electricTeal,
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(
                  labelText: 'RSS Feed URL',
                  hintText: 'https://anchor.fm/s/.../rss',
                  filled: true,
                  fillColor: AppColors.bg3,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _adding ? null : _addFeed,
                  icon: _adding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.bg0),
                        )
                      : const Icon(Icons.rss_feed_rounded, size: 16),
                  label: Text(_adding ? 'Adding…' : 'Add Feed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lionGreen,
                    foregroundColor: AppColors.bg0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.p16),

        // Feeds list
        feedsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Text('Error: $e', style: AppTextStyles.caption),
          data: (feeds) {
            if (feeds.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.p24),
                  child: Column(
                    children: [
                      const Icon(Icons.rss_feed_rounded,
                          color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 16),
                      Text('No RSS feeds yet.', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Paste a podcast RSS URL above to import episodes.',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: feeds
                  .map((feed) => _FeedCard(feed: feed))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _FeedCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> feed;
  const _FeedCard({required this.feed});

  @override
  ConsumerState<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends ConsumerState<_FeedCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final url = widget.feed['url'] as String? ?? '';
    final name = widget.feed['name'] as String? ?? url;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.p12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r12),
        border: Border.all(color: AppColors.border1),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.lionGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.rss_feed_rounded,
                  color: AppColors.lionGreen, size: 18),
            ),
            title: Text(name, style: AppTextStyles.bodyMedium),
            subtitle: Text(
              url,
              style: AppTextStyles.caption.copyWith(color: AppColors.electricTeal),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.liveRed, size: 20),
                  onPressed: () => widget.feed['id'] != null
                      ? FirebaseFirestore.instance
                          .collection('podcast_feeds')
                          .doc(widget.feed['id'] as String)
                          .delete()
                      : null,
                ),
              ],
            ),
          ),
          if (_expanded) _FeedEpisodes(feedUrl: url, feedName: name),
        ],
      ),
    );
  }
}

class _FeedEpisodes extends ConsumerWidget {
  final String feedUrl;
  final String feedName;
  const _FeedEpisodes({required this.feedUrl, required this.feedName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodesAsync = ref.watch(_rssFeedEpisodesProvider(feedUrl));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: episodesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text(
          'Could not load feed: $e',
          style: AppTextStyles.caption.copyWith(color: AppColors.errorRed),
        ),
        data: (episodes) {
          if (episodes.isEmpty) {
            return Text(
              'No episodes found in this feed.',
              style: AppTextStyles.caption,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${episodes.length} episode${episodes.length == 1 ? '' : 's'}',
                style: AppTextStyles.caption.copyWith(color: AppColors.electricTeal),
              ),
              const SizedBox(height: 8),
              ...episodes.take(5).map((ep) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.mic_rounded,
                            color: AppColors.textMuted, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ep.title, style: AppTextStyles.bodySmall),
                              if (ep.duration != null)
                                Text(ep.duration!,
                                    style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              if (episodes.length > 5)
                Text(
                  '+ ${episodes.length - 5} more',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Uploaded tab ─────────────────────────────────────────────────────────────

class _UploadedTab extends StatelessWidget {
  const _UploadedTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.upload_file_rounded,
                color: AppColors.textMuted, size: 56),
            const SizedBox(height: 16),
            Text('Direct Upload', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Upload individual episode files directly to Firebase Storage. '
              'This uses Firebase Storage quota — RSS feeds above are recommended for regular shows.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Direct upload requires the Firebase Storage setup — use RSS feeds for now')),
              ),
              icon: const Icon(Icons.upload_rounded),
              label: const Text('Upload Episode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lionGreen,
                foregroundColor: AppColors.bg0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
