import 'dart:collection';

/// A raw BLE notification received from the blood-pressure monitor.
///
/// This model always preserves the original notification unchanged. A
/// separate provisional YK-IBPA1 decoder interprets only the confirmed packet
/// positions while additional physical comparisons are collected.
class BpMonitorPacket {
  BpMonitorPacket({
    required this.index,
    required List<int> bytes,
    required this.receivedAt,
    this.isHighlighted = false,
    this.highlightReasons = const [],
  }) : bytes = UnmodifiableListView<int>(List<int>.from(bytes));

  factory BpMonitorPacket.fromNotification({
    required int index,
    required List<int> bytes,
    required DateTime receivedAt,
    required bool compareAgainstProgressStructure,
  }) {
    final reasons = <String>[];
    if (bytes.length != 15) {
      reasons.add('Packet length differs from 15 bytes');
    }
    if (bytes.isEmpty || bytes.first != 0x80) {
      reasons.add('First byte is not 0x80');
    }
    if (bytes.length > 3 && bytes.skip(3).any((byte) => byte != 0)) {
      reasons.add('A byte after index 2 is nonzero');
    }
    if (compareAgainstProgressStructure && !matchesProgressStructure(bytes)) {
      reasons.add('Structure differs from preceding progress packets');
    }

    return BpMonitorPacket(
      index: index,
      bytes: bytes,
      receivedAt: receivedAt,
      isHighlighted: reasons.isNotEmpty,
      highlightReasons: List<String>.unmodifiable(reasons),
    );
  }

  final int index;
  final List<int> bytes;
  final DateTime receivedAt;
  final bool isHighlighted;
  final List<String> highlightReasons;

  int get length => bytes.length;

  String get decimalString => '[${bytes.join(', ')}]';

  String get hexadecimalString => formatHex(bytes);

  bool get matchesKnownProgressStructure => matchesProgressStructure(bytes);

  /// Groups packets by byte-position structure instead of exact values.
  ///
  /// The counter-like byte at index 2 is normalized for the observed
  /// `80 00 XX 00...` progress packet pattern.
  String get structureSignature {
    if (matchesKnownProgressStructure) {
      return 'length=15|80 00 XX 00x12';
    }
    final nonzeroPattern = bytes
        .map((byte) => byte == 0 ? '00' : 'NZ')
        .join(' ');
    return 'length=$length|$nonzeroPattern';
  }

  Map<String, Object> toJson() {
    return {
      'index': index,
      'timestamp': receivedAt.toIso8601String(),
      'decimalBytes': List<int>.from(bytes),
      'hex': hexadecimalString,
      'length': length,
      'highlighted': isHighlighted,
      'highlightReasons': List<String>.from(highlightReasons),
    };
  }

  static bool matchesProgressStructure(List<int> bytes) {
    if (bytes.length != 15 || bytes[0] != 0x80 || bytes[1] != 0x00) {
      return false;
    }
    return bytes.skip(3).every((byte) => byte == 0);
  }

  static String formatHex(Iterable<int> bytes) {
    return bytes
        .map(
          (byte) =>
              (byte & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase(),
        )
        .join(' ');
  }
}
