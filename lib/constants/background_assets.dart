import 'package:flutter/material.dart';

/// Represents a background asset (paper or image)
class BackgroundAsset {
  final String id;
  final String name;
  final String? assetPath;
  final bool isPaper;
  final Color? fallbackColor;

  const BackgroundAsset({
    required this.id,
    required this.name,
    this.assetPath,
    this.isPaper = false,
    this.fallbackColor,
  });
}

/// Central registry of all background assets
class BackgroundAssets {
  BackgroundAssets._();

  // ════════════════════════════════════════════════════════════════════════════
  // PAPER TYPES (NOW JPG - NO MORE PDFs!)
  // ════════════════════════════════════════════════════════════════════════════

  static const List<BackgroundAsset> allPapers = [
    // Black paper (default)
    BackgroundAsset(
      id: 'paper_black',
      name: 'Black Paper',
      assetPath: null, // CODED - pure black
      isPaper: true,
      fallbackColor: Color(0xFF000000), // Pure black
    ),
    // Plain white paper (CODED - no image)
    BackgroundAsset(
      id: 'paper_plain',
      name: 'Plain White',
      assetPath: null, // CODED
      isPaper: true,
      fallbackColor: Color(0xFFFFFFFF), // Pure white
    ),
    // Lined notebook (IMAGE - user will add)
    BackgroundAsset(
      id: 'paper_lined',
      name: 'Lined Paper',
      assetPath: 'assets/backgrounds/lined_paper.jpg', // USER WILL ADD THIS
      isPaper: true,
      fallbackColor: Color(0xFFF5F5F5), // Light grey
    ),
    // Vintage paper (IMAGE ONLY)
    BackgroundAsset(
      id: 'paper_vintage',
      name: 'Vintage Paper',
      assetPath: 'assets/backgrounds/vintage_paper.jpg',
      isPaper: true,
      fallbackColor: Color(0xFFF5E6D3), // Beige/tan
    ),
  ];

  // ════════════════════════════════════════════════════════════════════════════
  // IMAGE BACKGROUNDS (All cleaned up - no duplicates!)
  // ════════════════════════════════════════════════════════════════════════════

  static const List<BackgroundAsset> allBackgrounds = [
    // GRADIENT (only one - blue gradient)
    BackgroundAsset(
      id: 'bg_gradient_blue',
      name: 'Blue Gradient',
      assetPath: 'assets/backgrounds/gradient_blue.jpg',
      isPaper: false,
      fallbackColor: Color(0xFF3F51B5),
    ),
    // NATURE BACKGROUNDS
    BackgroundAsset(
      id: 'bg_beach_aerial',
      name: 'Beach Aerial',
      assetPath: 'assets/backgrounds/beach_aerial.jpg',
      isPaper: false,
      fallbackColor: Color(0xFF2196F3),
    ),
    BackgroundAsset(
      id: 'bg_blue_jungle',
      name: 'Blue Jungle',
      assetPath: 'assets/backgrounds/blue_jungle.jpg',
      isPaper: false,
      fallbackColor: Color(0xFF1B5E20),
    ),
    BackgroundAsset(
      id: 'bg_desert_dunes',
      name: 'Desert Dunes',
      assetPath: 'assets/backgrounds/desert_dunes.jpg',
      isPaper: false,
      fallbackColor: Color(0xFFD4A574),
    ),
    BackgroundAsset(
      id: 'bg_forest_path',
      name: 'Forest Path',
      assetPath: 'assets/backgrounds/forest_path.jpg',
      isPaper: false,
      fallbackColor: Color(0xFF2D5016),
    ),
    BackgroundAsset(
      id: 'bg_ocean_waves',
      name: 'Ocean Waves',
      assetPath: 'assets/backgrounds/ocean_waves.jpg',
      isPaper: false,
      fallbackColor: Color(0xFF0277BD),
    ),
    BackgroundAsset(
      id: 'bg_sea_rocks',
      name: 'Sea & Rocks',
      assetPath: 'assets/backgrounds/sea_rocks.jpg',
      isPaper: false,
      fallbackColor: Color(0xFF0077B6),
    ),
    BackgroundAsset(
      id: 'bg_yellow_sunset',
      name: 'Yellow Sunset',
      assetPath: 'assets/backgrounds/yellow_sunset.jpg',
      isPaper: false,
      fallbackColor: Color(0xFFFFA726),
    ),
    // SPACE BACKGROUNDS
    BackgroundAsset(
      id: 'bg_galaxy_panorama',
      name: 'Galaxy Panorama',
      assetPath: 'assets/backgrounds/galaxy_panorama.jpg',
      isPaper: false,
      fallbackColor: Color(0xFF0D1B2A),
    ),
    BackgroundAsset(
      id: 'bg_galaxy_stars',
      name: 'Galaxy Stars',
      assetPath: 'assets/backgrounds/galaxy_stars.jpg',
      isPaper: false,
      fallbackColor: Color(0xFF1A1A2E),
    ),
  ];

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════════════════════════

  /// Get all available backgrounds (papers + images)
  static List<BackgroundAsset> get all => [...allPapers, ...allBackgrounds];

  /// Find a background by its ID, returns null if not found
  static BackgroundAsset? findById(String id) {
    try {
      return all.firstWhere((bg) => bg.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if a background ID exists
  static bool exists(String id) => findById(id) != null;
}
