import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/features/ai_assistant/presentation/ai_chat_screen.dart';
import 'package:oma/features/cart/presentation/cart_screen.dart';
import 'package:oma/features/catalog/presentation/catalog_screen.dart';
import 'package:oma/features/favorites/presentation/favorites_screen.dart';
import 'package:oma/features/home/presentation/home_screen.dart';
import 'package:oma/features/installation/presentation/installation_flow_screen.dart';
import 'package:oma/features/my_home/presentation/missing_items_screen.dart';
import 'package:oma/features/my_home/presentation/my_home_screens.dart';
import 'package:oma/features/my_home/presentation/room_purchases_screen.dart';
import 'package:oma/features/my_home/presentation/room_screen.dart';
import 'package:oma/features/my_home/presentation/suggestions_screen.dart';
import 'package:oma/features/onboarding/presentation/onboarding_screens.dart';
import 'package:oma/features/orders/presentation/orders_screen.dart';
import 'package:oma/features/product_details/presentation/product_screen.dart';
import 'package:oma/features/profile/presentation/profile_screen.dart';
import 'package:oma/features/room_3d/presentation/room_3d_screen.dart';
import 'package:oma/widgets/oma_chrome.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingWelcomeScreen(),
        routes: [
          GoRoute(
            path: 'housing',
            builder: (context, state) => const OnboardingHousingScreen(),
          ),
          GoRoute(
            path: 'photos',
            builder: (context, state) => const OnboardingPhotosScreen(),
          ),
          GoRoute(
            path: 'needs',
            builder: (context, state) => const OnboardingNeedsScreen(),
          ),
          GoRoute(
            path: 'draft',
            builder: (context, state) => const OnboardingDraftDoneScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return OmaShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.catalog,
                builder: (context, state) => const CatalogScreen(),
                routes: [
                  GoRoute(
                    path: 'product/:productId',
                    builder: (context, state) => ProductScreen(
                      productId: state.pathParameters['productId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'install',
                        builder: (context, state) => InstallationFlowScreen(
                          productId: state.pathParameters['productId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.favorites,
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'my-home',
                    builder: (context, state) => const MyHomeListScreen(),
                  ),
                  GoRoute(
                    path: 'orders',
                    builder: (context, state) => const OrdersScreen(),
                  ),
                  GoRoute(
                    path: 'property/:propertyId',
                    builder: (context, state) => PropertyDetailScreen(
                      propertyId: state.pathParameters['propertyId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => PropertyEditScreen(
                          propertyId: state.pathParameters['propertyId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'layout',
                        builder: (context, state) => PropertyLayoutScreen(
                          propertyId: state.pathParameters['propertyId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'room/:roomId',
                        builder: (context, state) => RoomScreen(
                          propertyId: state.pathParameters['propertyId']!,
                          roomId: state.pathParameters['roomId']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'edit',
                            builder: (context, state) => RoomEditScreen(
                              propertyId: state.pathParameters['propertyId']!,
                              roomId: state.pathParameters['roomId']!,
                            ),
                          ),
                          GoRoute(
                            path: 'ai',
                            builder: (context, state) => AiChatScreen(
                              propertyId: state.pathParameters['propertyId']!,
                              roomId: state.pathParameters['roomId']!,
                            ),
                          ),
                          GoRoute(
                            path: '3d',
                            builder: (context, state) => Room3dScreen(
                              propertyId: state.pathParameters['propertyId']!,
                              roomId: state.pathParameters['roomId']!,
                            ),
                          ),
                          GoRoute(
                            path: 'suggestions',
                            builder: (context, state) => SuggestionsScreen(
                              propertyId: state.pathParameters['propertyId']!,
                              roomId: state.pathParameters['roomId']!,
                            ),
                          ),
                          GoRoute(
                            path: 'missing',
                            builder: (context, state) => MissingItemsScreen(
                              propertyId: state.pathParameters['propertyId']!,
                              roomId: state.pathParameters['roomId']!,
                            ),
                          ),
                          GoRoute(
                            path: 'purchases',
                            builder: (context, state) => RoomPurchasesScreen(
                              propertyId: state.pathParameters['propertyId']!,
                              roomId: state.pathParameters['roomId']!,
                            ),
                          ),
                          GoRoute(
                            path: 'saved',
                            builder: (context, state) => RoomSavedScreen(
                              propertyId: state.pathParameters['propertyId']!,
                              roomId: state.pathParameters['roomId']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
