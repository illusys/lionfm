class AppStrings {
  AppStrings._();

  // App identity
  static const String appName = 'Lion FM';
  static const String appFullName = 'Lion FM 91.1 MHz';
  static const String tagline = '...Your interactive radio';
  static const String appSubtitle = 'Official Campus Radio · University of Nigeria, Nsukka';
  static const String licenseInfo = 'NBC Licensed · Since 1999';

  // Stream URL — empty; real URL is loaded from Firestore stream_config/current
  static const String liveStreamUrl = '';
  static const String fallbackStreamUrl = '';

  // API / Web
  static const String apiBaseUrl = 'https://api.lionfm.online';
  static const String webUrl = 'https://www.lionfm.online';

  // Navigation labels
  static const String navHome = 'Home';
  static const String navSchedule = 'Schedule';
  static const String navPodcasts = 'Podcasts';
  static const String navNews = 'News';
  static const String navRequests = 'Requests';

  // Screen titles
  static const String scheduleTitle = 'Schedule';
  static const String podcastsTitle = 'Podcasts';
  static const String newsTitle = 'Campus News';
  static const String requestsTitle = 'Requests';
  static const String settingsTitle = 'Settings';

  // Home screen
  static const String onAirNow = 'ON AIR NOW · LION FM 91.1 MHz';
  static const String liveBadge = '● LIVE';
  static const String upNext = 'UP NEXT TODAY';
  static const String viewFullSchedule = 'View full schedule →';
  static const String quickActions = 'QUICK ACCESS';
  static const String latestEpisodes = 'Latest episodes';
  static const String todaysShows = "Today's shows";
  static const String dedicateASong = 'Dedicate a song';
  static const String campusUpdates = 'Campus updates';

  // Player
  static const String liveLabel = 'LIVE';
  static const String buffering = 'Buffering…';
  static const String connecting = 'Connecting…';
  static const String reconnecting = 'Reconnecting…';
  static const String offAir = 'Lion FM is currently off-air';
  static const String noStreamConfigured = 'Stream offline — no URL configured';
  static const String retryStream = 'Tap to retry';

  // Requests
  static const String songRequestTab = '🎵 Song Request';
  static const String showPitchTab = '🎙 Show Pitch';
  static const String sendRequest = 'Send Request 🎵';
  static const String submitPitch = 'Submit Show Pitch 🎙';
  static const String requestSent = 'Request Sent!';
  static const String pitchReceived = 'Pitch Received!';
  static const String sendAnother = 'Send Another →';
  static const String backToHome = 'Back to Home';

  // Form labels
  static const String songTitle = 'Song Title';
  static const String artistName = 'Artist Name';
  static const String dedicateTo = 'Dedicate To';
  static const String yourName = 'Your Name';
  static const String showToPlayOn = 'Show to Play On';
  static const String message = 'Message';
  static const String showConcept = 'Show Name / Concept';
  static const String department = 'Your Department';
  static const String preferredSlot = 'Preferred Time Slot';
  static const String format = 'Format';
  static const String briefDescription = 'Brief Description';
  static const String contactInfo = 'Contact (WhatsApp/Email)';

  // Form hints
  static const String dedicateHint = 'e.g. My study group 💛';
  static const String departmentHint = 'e.g. Faculty of Law, 300 Level';
  static const String messageHint = 'Say something to your dedicatee…';

  // Validation errors
  static const String fieldRequired = 'This field is required';
  static const String invalidEmail = 'Enter a valid email address';
  static const String tooLong = 'Too many characters';

  // Settings
  static const String premium = 'Premium ⭐';
  static const String freeTier = 'Free';
  static const String goPremium = 'Go Premium — Ad-Free';
  static const String premiumSubtitle =
      'Remove all ads, download episodes, unlock exclusive content.';
  static const String premiumPrice = '₦1,000 / month';
  static const String notificationsSection = 'NOTIFICATIONS';
  static const String audioQualitySection = 'AUDIO QUALITY';
  static const String aboutSection = 'ABOUT';

  // Notification toggle labels
  static const String showAlerts = 'Show Alerts';
  static const String showAlertsSubtitle = "When your favourited shows go live";
  static const String breakingNews = 'Breaking News';
  static const String breakingNewsSubtitle = 'Campus news alerts from @lionfmunn';
  static const String requestConfirmation = 'Request Confirmation';
  static const String requestConfirmationSubtitle =
      'When your song is about to be played';
  static const String specialEvents = 'Special Events';
  static const String specialEventsSubtitle =
      'Convocation, inaugurals, sports';

  // Audio quality options
  static const String dataSaver = 'Data Saver';
  static const String dataSaverSubtitle = '64 kbps · Lowest data use';
  static const String standard = 'Standard';
  static const String standardSubtitle = '128 kbps · Recommended';
  static const String highQuality = 'High Quality';
  static const String highQualitySubtitle = '320 kbps · Premium only';

  // Toasts / snackbars
  static const String reminderSet =
      "Reminder set! We'll notify you 10 minutes before this show.";
  static const String premiumActivated =
      'Premium activated — now streaming in High Quality 🎉';
  static const String welcomePremium = '✓ Welcome to Premium! 🎉';
  static const String paymentCancelled = 'Payment cancelled.';

  // Error states
  static const String errorGeneral = 'Something went wrong';
  static const String errorNetwork = 'No internet connection';
  static const String errorStream = 'Unable to connect to stream';
  static const String retryButton = 'Retry';

  // Empty states
  static const String emptyEpisodes = 'No episodes found';
  static const String emptyEpisodesSubtitle =
      'Try a different search or category';
  static const String emptyNews = 'No news right now';
  static const String emptySchedule = 'No shows scheduled';

  // Offline
  static const String offlineBanner =
      "You're offline — showing cached content. Live stream unavailable.";
  static const String offlineHomeAlert =
      "You're offline — stream will resume when connected";

  // Share text
  static const String shareListening =
      "I'm listening to %s on Lion FM 91.1 MHz! Stream live at www.lionfm.online";
  static const String shareNews =
      '%s — via Lion FM 91.1 MHz · www.lionfm.online';

  // About
  static const String aboutLionFm = 'Lion FM 91.1 MHz';
  static const String aboutPlatform = 'Platform by iLLuSys LTD v1.0.0';
  static const String privacyPolicy = 'Privacy Policy — NDPR Compliant';
  static const String rateApp = 'Rate the App';
  static const String contactLionFm = 'Contact Lion FM';
  static const String contactEmail = 'mailto:studio@lionfm.online';
  static const String privacyUrl = 'https://www.lionfm.online/privacy';

  // Social
  static const String twitterHandle = '@lionfmunn';

  // Admin PIN
  static const String defaultAdminPin = '1911';
}
