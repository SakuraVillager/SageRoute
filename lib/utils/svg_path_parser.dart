import 'dart:math' as math;
import 'dart:ui' as ui;

/// 将 SVG 路径数据（d 属性字符串）解析为 Flutter [ui.Path]。
///
/// 支持常见 SVG 路径命令：
/// M/m, L/l, H/h, V/v, C/c, S/s, Q/q, T/t, A/a, Z/z
class SvgPathParser {
  final List<String> _tokens = [];
  int _pos = 0;

  ui.Path parse(String d) {
    _tokens.clear();
    _pos = 0;

    _tokenize(d);

    final path = ui.Path();
    double currentX = 0;
    double currentY = 0;
    double startX = 0;
    double startY = 0;
    double? lastControlX;
    double? lastControlY;
    String? lastCommand;

    while (_pos < _tokens.length) {
      final token = _tokens[_pos];
      if (_isCommand(token)) {
        final cmd = token;
        _pos++;
        lastCommand = cmd;
        switch (cmd) {
          case 'M':
            currentX = _nextDouble();
            currentY = _nextDouble();
            startX = currentX;
            startY = currentY;
            path.moveTo(currentX, currentY);
            while (_peekIsNumber()) {
              currentX = _nextDouble();
              currentY = _nextDouble();
              path.lineTo(currentX, currentY);
            }
          case 'm':
            currentX += _nextDouble();
            currentY += _nextDouble();
            startX = currentX;
            startY = currentY;
            path.moveTo(currentX, currentY);
            while (_peekIsNumber()) {
              currentX += _nextDouble();
              currentY += _nextDouble();
              path.lineTo(currentX, currentY);
            }
          case 'L':
            while (_peekIsNumber()) {
              currentX = _nextDouble();
              currentY = _nextDouble();
              path.lineTo(currentX, currentY);
            }
          case 'l':
            while (_peekIsNumber()) {
              currentX += _nextDouble();
              currentY += _nextDouble();
              path.lineTo(currentX, currentY);
            }
          case 'H':
            while (_peekIsNumber()) {
              currentX = _nextDouble();
              path.lineTo(currentX, currentY);
            }
          case 'h':
            while (_peekIsNumber()) {
              currentX += _nextDouble();
              path.lineTo(currentX, currentY);
            }
          case 'V':
            while (_peekIsNumber()) {
              currentY = _nextDouble();
              path.lineTo(currentX, currentY);
            }
          case 'v':
            while (_peekIsNumber()) {
              currentY += _nextDouble();
              path.lineTo(currentX, currentY);
            }
          case 'C':
            while (_peekIsNumber()) {
              final x1 = _nextDouble();
              final y1 = _nextDouble();
              final x2 = _nextDouble();
              final y2 = _nextDouble();
              final x = _nextDouble();
              final y = _nextDouble();
              path.cubicTo(x1, y1, x2, y2, x, y);
              lastControlX = x2;
              lastControlY = y2;
              currentX = x;
              currentY = y;
            }
          case 'c':
            while (_peekIsNumber()) {
              final x1 = currentX + _nextDouble();
              final y1 = currentY + _nextDouble();
              final x2 = currentX + _nextDouble();
              final y2 = currentY + _nextDouble();
              final x = currentX + _nextDouble();
              final y = currentY + _nextDouble();
              path.cubicTo(x1, y1, x2, y2, x, y);
              lastControlX = x2;
              lastControlY = y2;
              currentX = x;
              currentY = y;
            }
          case 'S':
            while (_peekIsNumber()) {
              double x2;
              double y2;
              if (lastCommand == 'C' ||
                  lastCommand == 'c' ||
                  lastCommand == 'S' ||
                  lastCommand == 's') {
                x2 = 2 * currentX - (lastControlX ?? currentX);
                y2 = 2 * currentY - (lastControlY ?? currentY);
              } else {
                x2 = currentX;
                y2 = currentY;
              }
              final x2e = _nextDouble();
              final y2e = _nextDouble();
              final x = _nextDouble();
              final y = _nextDouble();
              path.cubicTo(x2, y2, x2e, y2e, x, y);
              lastControlX = x2e;
              lastControlY = y2e;
              currentX = x;
              currentY = y;
            }
          case 's':
            while (_peekIsNumber()) {
              double x2;
              double y2;
              if (lastCommand == 'C' ||
                  lastCommand == 'c' ||
                  lastCommand == 'S' ||
                  lastCommand == 's') {
                x2 = 2 * currentX - (lastControlX ?? currentX);
                y2 = 2 * currentY - (lastControlY ?? currentY);
              } else {
                x2 = currentX;
                y2 = currentY;
              }
              final x2e = currentX + _nextDouble();
              final y2e = currentY + _nextDouble();
              final x = currentX + _nextDouble();
              final y = currentY + _nextDouble();
              path.cubicTo(x2, y2, x2e, y2e, x, y);
              lastControlX = x2e;
              lastControlY = y2e;
              currentX = x;
              currentY = y;
            }
          case 'Q':
            while (_peekIsNumber()) {
              final x1 = _nextDouble();
              final y1 = _nextDouble();
              final x = _nextDouble();
              final y = _nextDouble();
              path.quadraticBezierTo(x1, y1, x, y);
              lastControlX = x1;
              lastControlY = y1;
              currentX = x;
              currentY = y;
            }
          case 'q':
            while (_peekIsNumber()) {
              final x1 = currentX + _nextDouble();
              final y1 = currentY + _nextDouble();
              final x = currentX + _nextDouble();
              final y = currentY + _nextDouble();
              path.quadraticBezierTo(x1, y1, x, y);
              lastControlX = x1;
              lastControlY = y1;
              currentX = x;
              currentY = y;
            }
          case 'T':
            while (_peekIsNumber()) {
              double x1;
              double y1;
              if (lastCommand == 'Q' ||
                  lastCommand == 'q' ||
                  lastCommand == 'T' ||
                  lastCommand == 't') {
                x1 = 2 * currentX - (lastControlX ?? currentX);
                y1 = 2 * currentY - (lastControlY ?? currentY);
              } else {
                x1 = currentX;
                y1 = currentY;
              }
              final x = _nextDouble();
              final y = _nextDouble();
              path.quadraticBezierTo(x1, y1, x, y);
              lastControlX = x1;
              lastControlY = y1;
              currentX = x;
              currentY = y;
            }
          case 't':
            while (_peekIsNumber()) {
              double x1;
              double y1;
              if (lastCommand == 'Q' ||
                  lastCommand == 'q' ||
                  lastCommand == 'T' ||
                  lastCommand == 't') {
                x1 = 2 * currentX - (lastControlX ?? currentX);
                y1 = 2 * currentY - (lastControlY ?? currentY);
              } else {
                x1 = currentX;
                y1 = currentY;
              }
              final x = currentX + _nextDouble();
              final y = currentY + _nextDouble();
              path.quadraticBezierTo(x1, y1, x, y);
              lastControlX = x1;
              lastControlY = y1;
              currentX = x;
              currentY = y;
            }
          case 'A':
            while (_peekIsNumber()) {
              final result = _parseArcTo(path, currentX, currentY, false);
              currentX = result.$1;
              currentY = result.$2;
            }
          case 'a':
            while (_peekIsNumber()) {
              final result = _parseArcTo(path, currentX, currentY, true);
              currentX = result.$1;
              currentY = result.$2;
            }
          case 'Z':
          case 'z':
            path.close();
            currentX = startX;
            currentY = startY;
          default:
            break;
        }
      } else {
        // Shouldn't normally reach here; skip
        _pos++;
      }
    }

    return path;
  }

  /// Tokenizes the SVG path string into commands and numbers.
  void _tokenize(String d) {
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      final ch = d[i];
      if (ch == ',' || ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
        _flush(buf);
      } else if (ch == '-' || ch == '+') {
        // A sign starts a new number unless following an 'e' for scientific notation
        if (buf.isNotEmpty) {
          final last = buf.toString();
          if (last.endsWith('e') || last.endsWith('E')) {
            buf.write(ch);
            continue;
          }
        }
        _flush(buf);
        buf.write(ch);
      } else if (ch == '.') {
        // A dot starts a new number if the buffer already has a dot (two decimals)
        if (buf.isNotEmpty && buf.toString().contains('.')) {
          _flush(buf);
          buf.write(ch);
        } else {
          buf.write(ch);
        }
      } else if (_isLetter(ch)) {
        _flush(buf);
        _tokens.add(ch);
      } else {
        buf.write(ch);
      }
    }
    _flush(buf);
  }

  void _flush(StringBuffer buf) {
    if (buf.isNotEmpty) {
      _tokens.add(buf.toString());
      buf.clear();
    }
  }

  bool _isLetter(String ch) {
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  bool _isCommand(String token) {
    return token.length == 1 && _isLetter(token);
  }

  bool _peekIsNumber() {
    if (_pos >= _tokens.length) return false;
    return !_isCommand(_tokens[_pos]);
  }

  double _nextDouble() {
    if (_pos >= _tokens.length) return 0.0;
    final token = _tokens[_pos++];
    return double.tryParse(token) ?? 0.0;
  }

  bool _nextBool() {
    final v = _nextDouble();
    return v != 0;
  }

  /// Parses an SVG arc command and converts it to cubic bezier curves.
  /// Returns (endX, endY) of the arc.
  (double, double) _parseArcTo(
    ui.Path path,
    double currentX,
    double currentY,
    bool relative,
  ) {
    final rx = _nextDouble();
    final ry = _nextDouble();
    final xAxisRotation = _nextDouble();
    final largeArcFlag = _nextBool();
    final sweepFlag = _nextBool();
    final x = relative ? currentX + _nextDouble() : _nextDouble();
    final y = relative ? currentY + _nextDouble() : _nextDouble();

    _arcToCubicBeziers(
      path: path,
      startX: currentX,
      startY: currentY,
      rx: rx,
      ry: ry,
      x: x,
      y: y,
      rotation: xAxisRotation,
      largeArc: largeArcFlag,
      sweep: sweepFlag,
    );

    return (x, y);
  }

  /// Converts an SVG arc to a sequence of cubic Bezier curves.
  void _arcToCubicBeziers({
    required ui.Path path,
    required double startX,
    required double startY,
    required double rx,
    required double ry,
    required double x,
    required double y,
    required double rotation,
    required bool largeArc,
    required bool sweep,
  }) {
    if (rx == 0 || ry == 0 || (startX == x && startY == y)) {
      path.lineTo(x, y);
      return;
    }

    var absRx = rx.abs();
    var absRy = ry.abs();

    final double phi = rotation * math.pi / 180.0;
    final double cosPhi = math.cos(phi);
    final double sinPhi = math.sin(phi);

    final double dx2 = (startX - x) / 2.0;
    final double dy2 = (startY - y) / 2.0;
    final double x1p = cosPhi * dx2 + sinPhi * dy2;
    final double y1p = -sinPhi * dx2 + cosPhi * dy2;

    final double x1pSq = x1p * x1p;
    final double y1pSq = y1p * y1p;
    final double rxSq = absRx * absRx;
    final double rySq = absRy * absRy;

    // Correct radii if needed
    double lambda = x1pSq / rxSq + y1pSq / rySq;
    if (lambda > 1) {
      final double sq = math.sqrt(lambda);
      absRx *= sq;
      absRy *= sq;
    }

    final double rxSqC = absRx * absRx;
    final double rySqC = absRy * absRy;
    final double num = rxSqC * rySqC - rxSqC * y1pSq - rySqC * x1pSq;
    final double den = rxSqC * y1pSq + rySqC * x1pSq;
    final double sqDen = den > 0 ? den : 1.0;
    final double rad = num < 0 ? 0 : num / sqDen;
    double sqRad = math.sqrt(rad);

    if (largeArc == sweep) {
      sqRad = -sqRad;
    }

    double cxp = sqRad * (absRx * y1p) / absRy;
    double cyp = -sqRad * (absRy * x1p) / absRx;

    // Step 3: Compute (cx, cy)
    final double cx = cosPhi * cxp - sinPhi * cyp + (startX + x) / 2.0;
    final double cy = sinPhi * cxp + cosPhi * cyp + (startY + y) / 2.0;

    // Step 4: Compute the two angles
    double theta1;
    double dTheta;

    double ux = (x1p - cxp) / absRx;
    double uy = (y1p - cyp) / absRy;
    double vx = (-x1p - cxp) / absRx;
    double vy = (-y1p - cyp) / absRy;

    theta1 = _angle(1.0, 0.0, ux, uy);
    dTheta = _angle(ux, uy, vx, vy);

    if (!sweep && dTheta > 0) {
      dTheta -= 2 * math.pi;
    } else if (sweep && dTheta < 0) {
      dTheta += 2 * math.pi;
    }

    // Split the arc into cubic bezier segments (max 90 degrees each)
    final int segments = (dTheta.abs() / (math.pi / 2)).ceil();
    final double delta = dTheta / segments;
    final double t =
        (8.0 / 3.0) *
        math.sin(delta / 4.0) *
        math.sin(delta / 4.0) /
        math.sin(delta / 2.0);

    var currentAngle = theta1;
    var currentX2 = startX;
    var currentY2 = startY;

    for (var i = 0; i < segments; i++) {
      final double cosStart = math.cos(currentAngle);
      final double sinStart = math.sin(currentAngle);
      final double nextAngle = currentAngle + delta;
      final double cosEnd = math.cos(nextAngle);
      final double sinEnd = math.sin(nextAngle);

      // End point
      final double ex = cosPhi * absRx * cosEnd - sinPhi * absRy * sinEnd + cx;
      final double ey = sinPhi * absRx * cosEnd + cosPhi * absRy * sinEnd + cy;

      // Control point 1
      final double cp1x =
          currentX2 +
          t * (-cosPhi * absRx * sinStart - sinPhi * absRy * cosStart);
      final double cp1y =
          currentY2 +
          t * (sinPhi * absRx * sinStart + (-cosPhi) * absRy * cosStart);

      // Control point 2
      final double cp2x =
          ex + t * (cosPhi * absRx * sinEnd + sinPhi * absRy * cosEnd);
      final double cp2y =
          ey + t * (-sinPhi * absRx * sinEnd + cosPhi * absRy * cosEnd);

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, ex, ey);

      currentX2 = ex;
      currentY2 = ey;
      currentAngle = nextAngle;
    }
  }

  /// Computes the angle between vectors (ux, uy) and (vx, vy).
  double _angle(double ux, double uy, double vx, double vy) {
    final double dot = ux * vx + uy * vy;
    final double len =
        math.sqrt(ux * ux + uy * uy) * math.sqrt(vx * vx + vy * vy);
    if (len == 0) return 0;
    final double cosAngle = (dot / len).clamp(-1.0, 1.0);
    double angle = math.acos(cosAngle);
    if ((ux * vy - uy * vx) < 0) {
      angle = -angle;
    }
    return angle;
  }
}
