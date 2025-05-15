import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flame/collisions.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'player.dart';

class MapLoader extends Component with HasGameRef {
  late TiledComponent tiledMap;
  late Vector2 mapSize;
  late String currentMapPath;
  final List<RectangleHitbox> collisionBlocks = [];

  @override
  Future<void> onLoad() async {
    // Initialize with default values
    mapSize = Vector2.zero();
  }

  Future<void> loadMap(String mapPath) async {
    try {
      developer.log('Loading map: $mapPath');
      currentMapPath = mapPath;

      // Load the TMX map with correct path
      // The mapPath already includes 'images/' prefix, but we need to ensure it's loaded correctly
      tiledMap = await TiledComponent.load(mapPath, Vector2.all(16));
      developer.log('Loaded map with path: $mapPath');
      await add(tiledMap);
      developer.log('Map loaded successfully: $mapPath');

      // Get map dimensions
      final mapWidth =
          tiledMap.tileMap.map.width * tiledMap.tileMap.map.tileWidth;
      final mapHeight =
          tiledMap.tileMap.map.height * tiledMap.tileMap.map.tileHeight;
      mapSize = Vector2(mapWidth.toDouble(), mapHeight.toDouble());
      developer.log('Map dimensions: ${mapSize.x} x ${mapSize.y}');

      // Set up collision objects if they exist
      await _processCollisions();

      // Set up spawn points if they exist
      await _processSpawnPoints();
    } catch (e) {
      developer.log('Error loading map: $e', error: e);
      // Create an empty map as fallback
      mapSize = Vector2(800, 600);
    }
  }

  Future<void> _processCollisions() async {
    // Clear previous collision blocks
    for (final block in collisionBlocks) {
      block.removeFromParent();
    }
    collisionBlocks.clear();

    // Try different common names for collision layers
    final collisionLayerNames = [
      'Collisions',
      'Collision',
      'Obstacles',
      'Walls',
    ];

    for (final layerName in collisionLayerNames) {
      final collisionLayer = tiledMap.tileMap.getLayer<ObjectGroup>(layerName);

      if (collisionLayer != null) {
        developer.log('Found collision layer: $layerName');
        for (final obj in collisionLayer.objects) {
          // Create collision objects from object layer
          final position = Vector2(obj.x, obj.y);
          final size = Vector2(obj.width, obj.height);
          final collider = RectangleHitbox(
            position: position,
            size: size,
            isSolid: true,
          );

          collider.debugMode =
              true; // For debugging - can be removed in production
          collisionBlocks.add(collider);
          await add(collider);
        }
        developer.log('Added ${collisionBlocks.length} collision objects');

        // If we found and processed a collision layer, we can stop looking
        break;
      }
    }

    // If no collision objects were found, print a warning
    if (collisionBlocks.isEmpty) {
      developer.log(
        'Warning: No collision objects found in the map "$currentMapPath"',
      );
      developer.log(
        'Create an object layer named "Collisions" with rectangle objects to define collision areas.',
      );
    }
  }

  Future<void> _processSpawnPoints() async {
    // Find spawn points from the object layer
    final spawnLayer = tiledMap.tileMap.getLayer<ObjectGroup>('SpawnPoints');

    if (spawnLayer != null) {
      developer.log('Found spawn points layer');
      for (final obj in spawnLayer.objects) {
        // Handle spawn points
        if (obj.name == 'player_spawn') {
          final spawnPosition = Vector2(obj.x, obj.y);
          developer.log('Found player spawn at $spawnPosition');
          // If player is available in gameRef, set its position
          final playerComponent = gameRef.children.query<Player>();
          if (playerComponent.isNotEmpty) {
            playerComponent.first.position = spawnPosition;
            developer.log('Player position set to spawn point');
          }
        }
      }
    } else {
      developer.log(
        'No spawn points layer found, using map center for player spawn',
      );
    }
  }

  // Helper method to find position on map by tile coordinates
  Vector2 getTilePosition(int tileX, int tileY) {
    final tileWidth = tiledMap.tileMap.map.tileWidth.toDouble();
    final tileHeight = tiledMap.tileMap.map.tileHeight.toDouble();

    return Vector2(
      tileX * tileWidth + tileWidth / 2,
      tileY * tileHeight + tileHeight / 2,
    );
  }

  // Check if a position collides with any obstacle
  bool collidesWith(Vector2 position, Vector2 size) {
    for (final block in collisionBlocks) {
      if (_checkRectCollision(position, size, block.position, block.size)) {
        return true;
      }
    }
    return false;
  }

  // Simple AABB collision detection
  bool _checkRectCollision(
    Vector2 pos1,
    Vector2 size1,
    Vector2 pos2,
    Vector2 size2,
  ) {
    return pos1.x < pos2.x + size2.x &&
        pos1.x + size1.x > pos2.x &&
        pos1.y < pos2.y + size2.y &&
        pos1.y + size1.y > pos2.y;
  }
}
