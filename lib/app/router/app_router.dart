import 'package:devvault/features/collections/presentation/screens/add_vault_items_screen.dart';
import 'package:devvault/features/collections/presentation/screens/collection_detail_screen.dart';
import 'package:devvault/features/collections/presentation/screens/edit_collection_screen.dart';
import 'package:devvault/features/developer_tools/domain/entities/tool_file_entity.dart';
import 'package:devvault/features/developer_tools/presentation/screens/tool_file_preview_screen.dart';
import 'package:devvault/features/vault/presentation/screens/create_vault_item_screen.dart';
import 'package:devvault/features/vault/presentation/screens/edit_vault_item_screen.dart';
import 'package:devvault/features/vault/presentation/vault_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_shell.dart';
import '../../features/collections/presentation/collections_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/developer_tools/presentation/tools_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/vault/presentation/vault_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const vault = '/vault';
  static const tools = '/tools';
  static const collections = '/collections';
  static const collectionDetail = '/collections/:id';
  static const editCollection = '/collections/edit/:id';
  static const addVaultItems = '/collections/:id/add-items';
  static const settings = '/settings';
  static const vaultDetail = '/vault/:id';
  static const createVaultItem = '/vault/create';
  static const editVaultItem = '/vault/edit/:id';

  // Developer Tools
  static const toolFilePreview = '/tool-file-preview';

  static const search = '/search';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // ------------------------------------------------------------
      // Splash
      // ------------------------------------------------------------
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) {
          return const SplashScreen();
        },
      ),

      // ------------------------------------------------------------
      // Onboarding
      // ------------------------------------------------------------
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) {
          return const OnboardingScreen();
        },
      ),

      // ------------------------------------------------------------
      // Create Vault Item
      // ------------------------------------------------------------
      GoRoute(
        path: AppRoutes.createVaultItem,
        builder: (context, state) {
          return const CreateVaultItemScreen();
        },
      ),

      // ------------------------------------------------------------
      // Edit Vault Item
      // ------------------------------------------------------------
      GoRoute(
        path: AppRoutes.editVaultItem,
        builder: (context, state) {
          final itemId = state.pathParameters['id']!;

          return EditVaultItemScreen(
            itemId: itemId,
          );
        },
      ),

      // ------------------------------------------------------------
      // Vault Detail
      // ------------------------------------------------------------
      GoRoute(
        path: AppRoutes.vaultDetail,
        builder: (context, state) {
          final itemId = state.pathParameters['id']!;

          return VaultDetailScreen(
            itemId: itemId,
          );
        },
      ),

      // ------------------------------------------------------------
      // Collection Detail
      // ------------------------------------------------------------
      GoRoute(
        path: AppRoutes.collectionDetail,
        builder: (context, state) {
          final collectionId = state.pathParameters['id']!;

          return CollectionDetailScreen(
            collectionId: collectionId,
          );
        },
      ),

      // ------------------------------------------------------------
      // Add Vault Items to Collection
      // ------------------------------------------------------------
      GoRoute(
        path: AppRoutes.addVaultItems,
        builder: (context, state) {
          final collectionId = state.pathParameters['id']!;

          return AddVaultItemsScreen(
            collectionId: collectionId,
          );
        },
      ),

      // ------------------------------------------------------------
      // Edit Collection
      // ------------------------------------------------------------
      GoRoute(
        path: AppRoutes.editCollection,
        builder: (context, state) {
          final collectionId = state.pathParameters['id']!;

          return EditCollectionScreen(
            collectionId: collectionId,
          );
        },
      ),

      // ------------------------------------------------------------
      // Tool File Preview
      // ------------------------------------------------------------
      GoRoute(
        path: AppRoutes.toolFilePreview,
        builder: (context, state) {
          final file = state.extra as ToolFileEntity;

          return ToolFilePreviewScreen(
            file: file,
          );
        },
      ),

      // ------------------------------------------------------------
      // Main application
      // ------------------------------------------------------------
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(
            child: child,
          );
        },
        routes: [
          // ----------------------------------------------------------
          // Home
          // ----------------------------------------------------------
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: DashboardScreen(),
              );
            },
          ),

          // ----------------------------------------------------------
          // Vault
          // ----------------------------------------------------------
          GoRoute(
            path: AppRoutes.vault,
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: VaultScreen(),
              );
            },
          ),

          // ----------------------------------------------------------
          // Developer Tools
          // ----------------------------------------------------------
          GoRoute(
            path: AppRoutes.tools,
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: ToolsScreen(),
              );
            },
          ),

          // ----------------------------------------------------------
          // Collections
          // ----------------------------------------------------------
          GoRoute(
            path: AppRoutes.collections,
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: CollectionsScreen(),
              );
            },
          ),

          // ----------------------------------------------------------
          // Settings
          // ----------------------------------------------------------
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) {
              return const NoTransitionPage(
                child: SettingsScreen(),
              );
            },
          ),
        ],
      ),
    ],
  );
});