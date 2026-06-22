import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/text_styles.dart';
import '../../data/models/event_model.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/analytics_service.dart';
import '../../data/services/paystack_service.dart';
import '../../providers/audio_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/lion_fm_app_bar.dart';
import '../../widgets/common/login_prompt_sheet.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: const LionFmAppBar(title: 'Live Events'),
      body: upcomingAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_outlined,
                      size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('No upcoming events', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(
                    'Check back soon for live performances\nand special broadcasts.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.p16),
            itemCount: events.length,
            itemBuilder: (_, i) => _EventCard(event: events[i]),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading events: $e',
              style: AppTextStyles.body),
        ),
      ),
    );
  }
}

// ─── Event card ───────────────────────────────────────────────────────────────

class _EventCard extends ConsumerWidget {
  final EventModel event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final ticketAsync = ref.watch(ticketProvider(event.id));
    final hasPaid = ticketAsync.valueOrNull ?? false;
    final hasAccess = event.isFree ||
        (event.isPremiumFree && user.isPremium) ||
        hasPaid;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.p16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
        border: Border.all(
          color: event.isLive
              ? AppColors.liveRed.withValues(alpha: 0.6)
              : AppColors.border1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poster
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.r16)),
            child: event.posterUrl != null
                ? Image.network(
                    event.posterUrl!,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _PosterPlaceholder(event: event),
                  )
                : _PosterPlaceholder(event: event),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live badge
                if (event.isLive)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.liveRed,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.rFull),
                        ),
                        child: const Text('● LIVE NOW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            )),
                      ),
                    ]),
                  ),
                Text(event.title, style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEE, MMM d · h:mm a').format(event.startTime),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.electricTeal),
                ),
                const SizedBox(height: 8),
                Text(event.description,
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                // Price + access row
                Row(children: [
                  _PriceChip(event: event, user: user),
                  const Spacer(),
                  _AccessButton(
                    event: event,
                    hasAccess: hasAccess,
                    user: user,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  final EventModel event;
  const _PosterPlaceholder({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_rounded,
              size: 48, color: AppColors.lionGreen),
          const SizedBox(height: 8),
          Text(event.title,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
              maxLines: 2),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final EventModel event;
  final dynamic user;
  const _PriceChip({required this.event, required this.user});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    if (event.isFree) {
      label = 'FREE';
      color = AppColors.successGreen;
    } else if (event.isPremiumFree && user.isPremium) {
      label = 'FREE for Premium';
      color = AppColors.electricTeal;
    } else {
      label = '₦${NumberFormat('#,###').format(event.ticketPriceNGN)}';
      color = AppColors.lionGold;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.rFull),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: AppTextStyles.label.copyWith(color: color)),
    );
  }
}

class _AccessButton extends ConsumerWidget {
  final EventModel event;
  final bool hasAccess;
  final dynamic user;
  const _AccessButton(
      {required this.event, required this.hasAccess, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hasAccess && (event.isLive || event.streamUrl.isNotEmpty)) {
      return ElevatedButton.icon(
        onPressed: () => _watchEvent(context, ref),
        icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
        label: const Text('Watch Now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lionGreen,
          foregroundColor: AppColors.bg0,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }

    if (hasAccess && event.isUpcoming) {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.border1),
        ),
        child: const Text('Starts Soon'),
      );
    }

    if (!event.isFree) {
      return ElevatedButton.icon(
        onPressed: () => _buyTicket(context, ref),
        icon: const Icon(Icons.confirmation_number_outlined, size: 16),
        label: const Text('Buy Ticket'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lionGold,
          foregroundColor: AppColors.bg0,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _watchEvent(BuildContext context, WidgetRef ref) async {
    final handler = ref.read(audioHandlerProvider);
    await handler.playLiveRadio(event.streamUrl);
    ref.read(currentAudioSourceProvider.notifier).state =
        AudioSourceType.liveRadio;
    ref.read(currentEpisodeProvider.notifier).state = null;
    await AnalyticsService.logListenStart(showTitle: event.title);
    if (context.mounted) Navigator.of(context).maybePop();
  }

  Future<void> _buyTicket(BuildContext context, WidgetRef ref) async {
    final isGuest = ref.read(isGuestModeProvider);
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (isGuest || authUser == null) {
      await LoginPromptSheet.show(context,
          reason: 'Sign in to purchase event tickets.');
      return;
    }

    final service = PaystackService();
    final result = await service.chargeEventTicket(
      email: authUser.email ?? '',
      userId: authUser.uid,
      eventId: event.id,
      ticketPriceNGN: event.ticketPriceNGN,
    );

    if (!context.mounted) return;

    if (result is PaymentSuccess) {
      _showVerifyDialog(context, ref, result.reference);
    } else if (result is PaymentError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: AppColors.errorRed,
      ));
    }
  }

  void _showVerifyDialog(
      BuildContext context, WidgetRef ref, String reference) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Verify Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete payment in the browser, then tap Verify.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 8),
            Text('Ref: $reference', style: AppTextStyles.caption),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final vResult =
                  await PaystackService.verifyPayment(reference: reference);
              if (!context.mounted) return;
              if (vResult is PaymentSuccess) {
                await AnalyticsService.logEventTicketPurchase(
                    eventId: event.id,
                    priceNGN: event.ticketPriceNGN);
                ref.invalidate(ticketProvider(event.id));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Payment verified! Enjoy the event.'),
                  backgroundColor: AppColors.successGreen,
                ));
              } else if (vResult is PaymentError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(vResult.message),
                  backgroundColor: AppColors.errorRed,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lionGreen,
              foregroundColor: AppColors.bg0,
            ),
            child: const Text('Verify Payment'),
          ),
        ],
      ),
    );
  }
}
