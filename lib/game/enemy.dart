import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:developer' as developer;
import 'dungeon_game.dart';
import 'player.dart';

enum EnemyState { idle, patrol, chase, attack }

class Enemy extends SpriteAnimationComponent
    with HasGameRef<DungeonGame>, CollisionCallbacks {
  Enemy({
    required Vector2 position,
    required this.patrolPoints,
    this.detectionRadius = 150,
    this.speed = 50,
  }) : super(position: position, size: Vector2(32, 48), anchor: Anchor.center);

  final double speed;
  final double detectionRadius;
  final List<Vector2> patrolPoints;
  int currentPatrolIndex = 0;
  EnemyState state = EnemyState.patrol;
  bool _facingLeft = false;
  final _random = math.Random();
  double _idleTimer = 0;
  double _attackTimer = 0;
  final double _attackDuration = 0.5; // Duration of attack animation

  // Animation properties
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _patrolAnimation;
  late final SpriteAnimation _chaseAnimation;
  late final SpriteAnimation _attackAnimation;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load animations
    await _loadAnimations();

    // Set initial animation
    animation = _patrolAnimation;

    // Add collision detection
    add(
      CircleHitbox(
        radius: size.x / 2,
        position: size / 2,
        anchor: Anchor.center,
      ),
    );
  }

  Future<void> _loadAnimations() async {
    try {
      // For enemies, we'll use the player's run animation with a red tint
      final baseSprites = <Sprite>[];

      // Load the base sprites
      for (int i = 1; i <= 6; i++) {
        // Load the sprite
        final index = i <= 4 ? i : 4 - (i - 4); // Loop back for frames 5-6
        try {
          final sprite = Sprite(
            gameRef.images.fromCache('Player/run/$index.png'),
          );
          baseSprites.add(sprite);
        } catch (e) {
          developer.log('Error loading enemy animations: $e');
          // Create a fallback sprite if the image can't be loaded
          try {
            final fallbackSprite = Sprite(
              gameRef.images.fromCache('Player/idle/1.png'),
            );
            baseSprites.add(fallbackSprite);
          } catch (e) {
            developer.log('Error loading fallback sprite: $e');
          }
        }
      }

      // Create tinted versions for each animation state
      final idleSprites = _createTintedSprites(
        baseSprites,
        Colors.red.shade800,
      );
      final patrolSprites = _createTintedSprites(
        baseSprites,
        Colors.red.shade600,
      );
      final chaseSprites = _createTintedSprites(
        baseSprites,
        Colors.red.shade400,
      );
      final attackSprites = _createTintedSprites(
        baseSprites,
        Colors.red.shade200,
      );

      // Create animations with the tinted sprites
      _idleAnimation = SpriteAnimation.spriteList(idleSprites, stepTime: 0.2);
      _patrolAnimation = SpriteAnimation.spriteList(
        patrolSprites,
        stepTime: 0.15,
      );
      _chaseAnimation = SpriteAnimation.spriteList(chaseSprites, stepTime: 0.1);
      _attackAnimation = SpriteAnimation.spriteList(
        attackSprites,
        stepTime: 0.08,
      );
    } catch (e) {
      developer.log('Error in _loadAnimations: $e');
      // Create fallback animations with a single frame if loading fails
      try {
        final fallbackSprite = Sprite(
          gameRef.images.fromCache('images/Player/idle/1.png'),
        );
        final fallbackSprites = [fallbackSprite];
        _idleAnimation = SpriteAnimation.spriteList(
          fallbackSprites,
          stepTime: 0.2,
        );
        _patrolAnimation = SpriteAnimation.spriteList(
          fallbackSprites,
          stepTime: 0.2,
        );
        _chaseAnimation = SpriteAnimation.spriteList(
          fallbackSprites,
          stepTime: 0.2,
        );
        _attackAnimation = SpriteAnimation.spriteList(
          fallbackSprites,
          stepTime: 0.2,
        );
      } catch (e) {
        developer.log('Failed to create fallback animations: $e');
        // Create fallback animations with colored rectangles
        _createFallbackAnimations();
      }
    }
  }

  // Helper method to create tinted versions of sprites
  List<Sprite> _createTintedSprites(List<Sprite> baseSprites, Color tintColor) {
    final tintedSprites = <Sprite>[];

    for (final baseSprite in baseSprites) {
      // Create a new image with the tint applied
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the sprite with a color filter
      final paint =
          Paint()
            ..colorFilter = ColorFilter.mode(tintColor, BlendMode.modulate);

      // Draw the sprite onto the canvas with the tint
      baseSprite.render(
        canvas,
        position: Vector2.zero(),
        size: Vector2(32, 48),
        overridePaint: paint,
      );

      // Convert to an image
      final picture = recorder.endRecording();
      final img = picture.toImageSync(32, 48);

      // Create a new sprite from the tinted image
      tintedSprites.add(Sprite(img));
    }

    return tintedSprites;
  }

  void _createFallbackAnimations() {
    developer.log('Creating fallback animations for enemy');

    // Create a basic colored rectangle for each state
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, 32, 48);

    // Idle (dark red)
    canvas.drawRect(rect, Paint()..color = Colors.red.shade800);
    final idleImg = recorder.endRecording().toImageSync(32, 48);
    _idleAnimation = SpriteAnimation.spriteList([
      Sprite(idleImg),
    ], stepTime: 1.0);

    // Patrol (medium red)
    final recorder2 = PictureRecorder();
    final canvas2 = Canvas(recorder2);
    canvas2.drawRect(rect, Paint()..color = Colors.red.shade600);
    final patrolImg = recorder2.endRecording().toImageSync(32, 48);
    _patrolAnimation = SpriteAnimation.spriteList([
      Sprite(patrolImg),
    ], stepTime: 1.0);

    // Chase (light red)
    final recorder3 = PictureRecorder();
    final canvas3 = Canvas(recorder3);
    canvas3.drawRect(rect, Paint()..color = Colors.red.shade400);
    final chaseImg = recorder3.endRecording().toImageSync(32, 48);
    _chaseAnimation = SpriteAnimation.spriteList([
      Sprite(chaseImg),
    ], stepTime: 1.0);

    // Attack (very light red)
    final recorder4 = PictureRecorder();
    final canvas4 = Canvas(recorder4);
    canvas4.drawRect(rect, Paint()..color = Colors.red.shade200);
    final attackImg = recorder4.endRecording().toImageSync(32, 48);
    _attackAnimation = SpriteAnimation.spriteList([
      Sprite(attackImg),
    ], stepTime: 1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    switch (state) {
      case EnemyState.idle:
        _updateIdle(dt);
        break;
      case EnemyState.patrol:
        _updatePatrol(dt);
        break;
      case EnemyState.chase:
        _updateChase(dt);
        break;
      case EnemyState.attack:
        _updateAttack(dt);
        break;
    }

    // Update animation based on state
    _updateAnimation();
  }

  void _updateAnimation() {
    switch (state) {
      case EnemyState.idle:
        if (animation != _idleAnimation) {
          animation = _idleAnimation;
        }
        break;
      case EnemyState.patrol:
        if (animation != _patrolAnimation) {
          animation = _patrolAnimation;
        }
        break;
      case EnemyState.chase:
        if (animation != _chaseAnimation) {
          animation = _chaseAnimation;
        }
        break;
      case EnemyState.attack:
        if (animation != _attackAnimation) {
          animation = _attackAnimation;
        }
        break;
    }

    // Update facing direction
    if (_facingLeft) {
      transform.scale.x = -1;
    } else {
      transform.scale.x = 1;
    }
  }

  void _updateIdle(double dt) {
    // Wait for some time in idle state
    _idleTimer -= dt;
    if (_idleTimer <= 0) {
      state = EnemyState.patrol;
    }
  }

  void _updatePatrol(double dt) {
    if (patrolPoints.isEmpty) {
      state = EnemyState.idle;
      _idleTimer = 2 + _random.nextDouble() * 3;
      return;
    }

    // Check if player is in detection radius
    final player = _findPlayer();
    if (player != null) {
      final distanceToPlayer = position.distanceTo(player.position);
      if (distanceToPlayer < detectionRadius) {
        state = EnemyState.chase;
        return;
      }
    }

    // Move towards current patrol point
    final targetPoint = patrolPoints[currentPatrolIndex];
    final direction = targetPoint - position;
    final distance = direction.length;

    // If we've reached the point, move to next patrol point
    if (distance < 5) {
      currentPatrolIndex = (currentPatrolIndex + 1) % patrolPoints.length;
      // Briefly pause at waypoint
      state = EnemyState.idle;
      _idleTimer = 0.5 + _random.nextDouble();
      return;
    }

    // Update position
    final velocity = direction.normalized() * speed * dt;
    position += velocity;

    // Update facing direction
    if (velocity.x > 0 && _facingLeft) {
      _facingLeft = false;
    } else if (velocity.x < 0 && !_facingLeft) {
      _facingLeft = true;
    }
  }

  void _updateChase(double dt) {
    final player = _findPlayer();
    if (player == null) {
      state = EnemyState.patrol;
      return;
    }

    final distanceToPlayer = position.distanceTo(player.position);

    // If player moved out of detection range + buffer, return to patrol
    if (distanceToPlayer > detectionRadius * 1.5) {
      state = EnemyState.patrol;
      return;
    }

    // If close enough to attack
    if (distanceToPlayer < 40) {
      state = EnemyState.attack;
      _attackTimer = _attackDuration; // Set attack timer
      return;
    }

    // Chase the player
    final direction = player.position - position;
    final velocity = direction.normalized() * speed * dt;
    position += velocity;

    // Update facing direction
    if (velocity.x > 0 && _facingLeft) {
      _facingLeft = false;
    } else if (velocity.x < 0 && !_facingLeft) {
      _facingLeft = true;
    }
  }

  void _updateAttack(double dt) {
    // Decrease attack timer
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      // Return to chase after attack animation completes
      state = EnemyState.chase;
    }
  }

  Player? _findPlayer() {
    // Try to find the player component
    final playerComponents = gameRef.children.query<Player>();
    return playerComponents.isNotEmpty ? playerComponents.first : null;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Player && state == EnemyState.attack) {
      // Handle collision with player during attack
      // Add damage or other effects here
    }
  }

  // Helper method to handle player damage
  void _damagePlayer(Player player) {
    // TODO: Implement player damage logic
  }
}
