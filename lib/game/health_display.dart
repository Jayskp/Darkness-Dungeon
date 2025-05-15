import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'player.dart';

class HealthDisplay extends PositionComponent {
  final Player player;

  // Styling
  late final Paint _backgroundPaint;
  late final Paint _healthPaint;
  late final Paint _borderPaint;
  late final TextPaint _textPaint;

  // Bar dimensions
  final double barWidth;
  final double barHeight;

  HealthDisplay({
    required this.player,
    required Vector2 position,
    this.barWidth = 200,
    this.barHeight = 20,
  }) : super(position: position, size: Vector2(barWidth, barHeight));

  @override
  Future<void> onLoad() async {
    _backgroundPaint =
        Paint()
          ..color = Colors.grey.shade800
          ..style = PaintingStyle.fill;

    _healthPaint =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill;

    _borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    _textPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw background
    canvas.drawRect(Rect.fromLTWH(0, 0, barWidth, barHeight), _backgroundPaint);

    // Draw health fill
    final healthWidth = barWidth * player.healthPercentage;
    canvas.drawRect(Rect.fromLTWH(0, 0, healthWidth, barHeight), _healthPaint);

    // Draw border
    canvas.drawRect(Rect.fromLTWH(0, 0, barWidth, barHeight), _borderPaint);

    // Draw health text
    final healthText = '${player.currentHealth} / ${player.maxHealth}';
    _textPaint.render(
      canvas,
      healthText,
      Vector2(barWidth / 2, barHeight / 2),
      anchor: Anchor.center,
    );
  }
}
