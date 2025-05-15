import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/palette.dart';

class Minimap extends PositionComponent {
  final Component player;
  final Vector2 mapSize;
  late final Paint _backgroundPaint;
  late final Paint _borderPaint;
  late final Paint _playerDotPaint;
  late Vector2 _relativePlayerPosition;

  Minimap({
    required this.player,
    required this.mapSize,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    _backgroundPaint =
        Paint()
          ..color = const Color(0x88000000)
          ..style = PaintingStyle.fill;

    _borderPaint =
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    _playerDotPaint =
        Paint()
          ..color = const Color(0xFFFF0000)
          ..style = PaintingStyle.fill;

    _relativePlayerPosition = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    // Draw background and border
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _backgroundPaint);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _borderPaint);

    // Draw player dot
    final dotRadius = 4.0;
    canvas.drawCircle(
      Offset(_relativePlayerPosition.x, _relativePlayerPosition.y),
      dotRadius,
      _playerDotPaint,
    );

    super.render(canvas);
  }

  void updatePlayerPosition(Vector2 playerPosition) {
    // Convert player position to minimap coordinates
    _relativePlayerPosition = Vector2(
      (playerPosition.x / mapSize.x) * size.x,
      (playerPosition.y / mapSize.y) * size.y,
    );
  }
}
