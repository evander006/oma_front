abstract final class AppRoutes {
  static const home = '/';
  static const catalog = '/catalog';
  static const services = '/services';
  static const projects = '/projects';
  static const profile = '/profile';

  static const cart = '/cart';
  static const favorites = '/favorites';

  // Contractor marketplace: demo catalog, requests, and dashboard.
  static const masters = '/masters';
  static const myMasters = '/masters/mine';
  static const contractorDashboard = '/masters/contractor';
  static const masterProfile = '/masters/profile/:masterId';
  static const masterRequest = '/masters/request/:masterId';

  static const onboarding = '/onboarding';
  static const onboardingHousing = '/onboarding/housing';
  static const onboardingPhotos = '/onboarding/photos';
  static const onboardingNeeds = '/onboarding/needs';
  static const onboardingDraft = '/onboarding/draft';

  static const myHome = '/profile/my-home';
  static const property = '/profile/property/:propertyId';
  static const propertyPassport = '/profile/property/:propertyId/passport';
  static const propertyEdit = '/profile/property/:propertyId/edit';
  static const propertyLayout = '/profile/property/:propertyId/layout';
  static const room = '/profile/property/:propertyId/room/:roomId';
  static const roomEdit = '/profile/property/:propertyId/room/:roomId/edit';
  /// Top-level (outside shell) to avoid Navigator/Hero key clashes when
  /// opening chat from `/ai-design` and other root routes.
  static const roomAi = '/ai/room/:propertyId/:roomId';
  /// Top-level — same shell/root Navigator clash as room AI chat.
  static const room3d = '/room/:propertyId/:roomId/3d';
  static const property3d = '/home/:propertyId/3d';
  static const roomSuggestions =
      '/profile/property/:propertyId/room/:roomId/suggestions';
  static const roomMissing =
      '/profile/property/:propertyId/room/:roomId/missing';
  static const roomPurchases =
      '/profile/property/:propertyId/room/:roomId/purchases';
  static const roomSaved = '/profile/property/:propertyId/room/:roomId/saved';

  /// Top-level detail routes — safe to push from AI / shell / root stacks.
  static const product = '/product/:productId';
  static const installation = '/product/:productId/install';
  static const orders = '/profile/orders';
  static const loyalty = '/profile/loyalty';

  static const turnkey = '/services/turnkey';
  static const turnkeyDraft = '/services/turnkey/:requestId';
  static const serviceBooking = '/services/book/:serviceId';
  static const projectDetail = '/projects/:requestId';
  static const aiDesign = '/ai-design';
  static const aiDesignResults = '/ai-design/results';
  static const measurer = '/services/measurer';

  static String masterPath(String id) => '/masters/profile/$id';
  static String masterRequestPath(String id) => '/masters/request/$id';
  static String propertyPath(String id) => '/profile/property/$id';
  static String propertyPassportPath(String id) =>
      '/profile/property/$id/passport';
  static String propertyEditPath(String id) => '/profile/property/$id/edit';
  static String propertyLayoutPath(String id) => '/profile/property/$id/layout';
  static String roomPath(String propertyId, String roomId) =>
      '/profile/property/$propertyId/room/$roomId';
  static String roomEditPath(String propertyId, String roomId) =>
      '/profile/property/$propertyId/room/$roomId/edit';
  static String roomAiPath(String propertyId, String roomId) =>
      '/ai/room/$propertyId/$roomId';
  static String room3dPath(String propertyId, String roomId) =>
      '/room/$propertyId/$roomId/3d';
  static String property3dPath(String propertyId) => '/home/$propertyId/3d';
  static String roomSuggestionsPath(String propertyId, String roomId) =>
      '/profile/property/$propertyId/room/$roomId/suggestions';
  static String roomMissingPath(String propertyId, String roomId) =>
      '/profile/property/$propertyId/room/$roomId/missing';
  static String roomPurchasesPath(String propertyId, String roomId) =>
      '/profile/property/$propertyId/room/$roomId/purchases';
  static String roomSavedPath(String propertyId, String roomId) =>
      '/profile/property/$propertyId/room/$roomId/saved';
  static String productPath(String id) => '/product/$id';
  static String installPath(String id) => '/product/$id/install';
  static String turnkeyPath(String id) => '/services/turnkey/$id';
  static String serviceBookPath(String id) => '/services/book/$id';
  static String projectPath(String id) => '/projects/$id';
}
