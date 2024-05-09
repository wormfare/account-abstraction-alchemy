part of '../../account_abstraction_alchemy.dart';

class Tuple<T, R> {
  /// Field to store the first element of the tuple.
  final T item1;

  /// Field to store the second element of the tuple.
  final R item2;

  /// Constructor to initialize the tuple with the provided values.
  const Tuple(this.item1, this.item2);

  @override
  bool operator ==(Object other) {
    if (other is Tuple<T, R>) {
      return item1 == other.item1 && item2 == other.item2;
    }
    return false;
  }

  @override
  int get hashCode => item1.hashCode ^ item2.hashCode;

  @override
  String toString() => '($item1, $item2)';
}

RegExp _hexadecimal = RegExp(r'^[0-9a-fA-F]+$');

/// Converts a hex string to a 32bytes `Uint8List`.
///
/// Parameters:
/// - [hexString]: The input hex string.
///
/// Returns a Uint8List containing the converted bytes.
///
/// Example:
/// ```dart
/// final hexString = '0x1a2b3c';
/// final resultBytes = arrayify(hexString);
/// ```
Uint8List arrayify(String hexString) {
  hexString = hexString.replaceAll(RegExp(r'\s+'), '');
  List<int> bytes = [];
  for (int i = 0; i < hexString.length; i += 2) {
    String byteHex = hexString.substring(i, i + 2);
    int byteValue = int.parse(byteHex, radix: 16);
    bytes.add(byteValue);
  }
  return Uint8List.fromList(bytes);
}

/// Retrieves the X and Y components of an ECDSA public key from its bytes.
///
/// Parameters:
/// - [publicKeyBytes]: The bytes of the ECDSA public key.
///
/// Returns a Future containing a Tuple of two uint256 values representing the X and Y components of the public key.
///
/// Example:
/// ```dart
/// final publicKeyBytes = Uint8List.fromList([4, 1, 2, 3]); // Replace with actual public key bytes
/// final components = await getPublicKeyFromBytes(publicKeyBytes);
/// print(components); // Output: ['01', '02']
/// ```
Future<Tuple<Uint256, Uint256>> getPublicKeyFromBytes(
    Uint8List publicKeyBytes) async {
  final pKey = bytesUnwrapDer(publicKeyBytes, oidP256).sublist(1);
  final decodedX = hexlify(pKey.sublist(0, 32));
  final decodedY = hexlify(pKey.sublist(32, 64));
  return Tuple(Uint256.fromHex(decodedX), Uint256.fromHex(decodedY));
}

/// Parses ASN1-encoded signature bytes and returns a List of two hex strings representing the `r` and `s` values.
///
/// Parameters:
/// - [signatureBytes]: Uint8List containing the ASN1-encoded signature bytes.
///
/// Returns a Future<List<String>> containing hex strings for `r` and `s` values.
///
/// Example:
/// ```dart
/// final signatureBytes = Uint8List.fromList([48, 68, 2, 32, ...]);
/// final signatureHexValues = await getMessagingSignature(signatureBytes);
/// ```
Tuple<Uint256, Uint256> getMessagingSignature(Uint8List signatureBytes) {
  ASN1Parser parser = ASN1Parser(signatureBytes);
  ASN1Sequence parsedSignature = parser.nextObject() as ASN1Sequence;
  ASN1Integer rValue = parsedSignature.elements[0] as ASN1Integer;
  ASN1Integer sValue = parsedSignature.elements[1] as ASN1Integer;
  Uint8List rBytes = rValue.valueBytes();
  Uint8List sBytes = sValue.valueBytes();

  if (shouldRemoveLeadingZero(rBytes)) {
    rBytes = rBytes.sublist(1);
  }
  if (shouldRemoveLeadingZero(sBytes)) {
    sBytes = sBytes.sublist(1);
  }

  final r = hexlify(rBytes);
  final s = hexlify(sBytes);
  return Tuple(Uint256.fromHex(r), Uint256.fromHex(s));
}

/// Converts a list of integers to a hexadecimal string.
///
/// Parameters:
/// - [intArray]: The list of integers to be converted.
///
/// Returns a string representing the hexadecimal value.
///
/// Example:
/// ```dart
/// final intArray = [1, 15, 255];
/// final hexString = hexlify(intArray);
/// print(hexString); // Output: '0x01ff'
/// ```
String hexlify(List<int> intArray) {
  var ss = <String>[];
  for (int value in intArray) {
    ss.add(value.toRadixString(16).padLeft(2, '0'));
  }
  return "0x${ss.join('')}";
}

/// Throws an exception if the specified requirement is not met.
///
/// Parameters:
/// - [requirement]: The boolean requirement to be checked.
/// - [exception]: The exception message to be thrown if the requirement is not met.
///
/// Throws an exception with the specified message if the requirement is not met.
///
/// Example:
/// ```dart
/// final value = 42;
/// require(value > 0, "Value must be greater than 0");
/// print("Value is valid: $value");
/// ```
require(bool requirement, String exception) {
  if (!requirement) {
    throw Exception(exception);
  }
}

/// Computes the SHA-256 hash of the specified input.
///
/// Parameters:
/// - [input]: The list of integers representing the input data.
///
/// Returns a [Digest] object representing the SHA-256 hash.
///
/// Example:
/// ```dart
/// final data = utf8.encode("Hello, World!");
/// final hash = sha256Hash(data);
/// print("SHA-256 Hash: ${hash.toString()}");
/// ```
List<int> sha256Hash(List<int> input) {
  return SHA256.hash(input);
}

/// Checks whether the leading zero should be removed from the byte array.
///
/// Parameters:
/// - [bytes]: The list of integers representing the byte array.
///
/// Returns `true` if the leading zero should be removed, otherwise `false`.
///
/// Example:
/// ```dart
/// final byteData = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
/// final removeZero = shouldRemoveLeadingZero(byteData);
/// print("Remove Leading Zero: $removeZero");
/// ```
bool shouldRemoveLeadingZero(Uint8List bytes) {
  return bytes[0] == 0x0 && (bytes[1] & (1 << 7)) != 0;
}

/// Combines multiple lists of integers into a single list.
///
/// Parameters:
/// - [buff]: List of lists of integers to be combined.
///
/// Returns a new list containing all the integers from the input lists.
///
/// Example:
/// ```dart
/// final list1 = [1, 2, 3];
/// final list2 = [4, 5, 6];
/// final combinedList = toBuffer([list1, list2]);
/// print("Combined List: $combinedList");
/// ```
List<int> toBuffer(List<List<int>> buff) {
  return List<int>.from(buff.expand((element) => element).toList());
}

String padBase64(String b64) {
  final padding = 4 - b64.length % 4;
  return padding < 4 ? '$b64${"=" * padding}' : b64;
}

/// Decode a Base64 URL encoded string adding in any required '='
Uint8List b64d(String b64) => base64Url.decode(padBase64(b64));

/// Encode a byte list into Base64 URL encoding, stripping any trailing '='
String b64e(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

bool hexHasPrefix(String value) {
  return isHex(value, ignoreLength: true) && value.substring(0, 2) == '0x';
}

String hexStripPrefix(String value) {
  if (value.isEmpty) {
    return '';
  }
  if (hexHasPrefix(value)) {
    return value.substring(2);
  }
  final reg = RegExp(r'^[a-fA-F\d]+$');
  if (reg.hasMatch(value)) {
    return value;
  }
  throw Exception("unable to reach prefix");
}

/// [value] should be `0x` hex string.
Uint8List hexToU8a(String value, [int bitLength = -1]) {
  if (!isHex(value)) {
    throw ArgumentError.value(value, 'value', 'Not a valid hex string');
  }
  final newValue = hexStripPrefix(value);
  final valLength = newValue.length / 2;
  final bufLength = (bitLength == -1 ? valLength : bitLength / 8).ceil();
  final result = Uint8List(bufLength);
  final offset = max(0, bufLength - valLength).toInt();
  for (int index = 0; index < bufLength - offset; index++) {
    final subStart = index * 2;
    final subEnd =
        subStart + 2 <= newValue.length ? subStart + 2 : newValue.length;
    final arrIndex = index + offset;
    result[arrIndex] = int.parse(
      newValue.substring(subStart, subEnd),
      radix: 16,
    );
  }
  return result;
}

bool isHex(dynamic value, {int bits = -1, bool ignoreLength = false}) {
  if (value is! String) {
    return false;
  }
  if (value == '0x') {
    // Adapt Ethereum special cases.
    return true;
  }
  if (value.startsWith('0x')) {
    value = value.substring(2);
  }
  if (_hexadecimal.hasMatch(value)) {
    if (bits != -1) {
      return value.length == (bits / 4).ceil();
    }
    return ignoreLength || value.length % 2 == 0;
  }
  return false;
}

// 1.2.840.10045.3.1.7
final oidP256 = Uint8List.fromList([
  ...[0x30, 0x13],
  ...[0x06, 0x07], // OID with 7 bytes
  ...[0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01], // SEQUENCE
  ...[0x06, 0x08], // OID with 8 bytes
  ...[
    0x2a,
    0x86,
    0x48,
    0xce,
    0x3d,
    0x03,
    0x01,
    0x07,
  ]
]);

bool bufEquals(ByteBuffer b1, ByteBuffer b2) {
  if (b1.lengthInBytes != b2.lengthInBytes) return false;
  final u1 = Uint8List.fromList(b1.asUint8List());
  final u2 = Uint8List.fromList(b2.asUint8List());
  for (int i = 0; i < u1.length; i++) {
    if (u1[i] != u2[i]) {
      return false;
    }
  }
  return true;
}

/// Extracts a payload from the given `derEncoded` data, and checks that it was
/// tagged with the given `oid`.
///
/// `derEncoded = SEQUENCE(oid, BITSTRING(payload))`
///
/// [derEncoded] is the DER encoded and tagged data.
/// [oid] is the DER encoded (and SEQUENCE wrapped!) expected OID
Uint8List bytesUnwrapDer(Uint8List derEncoded, Uint8List oid) {
  int offset = 0;
  final buf = Uint8List.fromList(derEncoded);

  void check(int expected, String name) {
    if (buf[offset] != expected) {
      throw ArgumentError.value(
        buf[offset],
        name,
        'Expected $expected for $name but got',
      );
    }
    offset++;
  }

  check(0x30, 'sequence');
  offset += decodeLenBytes(buf, offset);
  if (!bufEquals(
    buf.sublist(offset, offset + oid.lengthInBytes).buffer,
    oid.buffer,
  )) {
    throw StateError('Not the expecting OID.');
  }
  offset += oid.lengthInBytes;
  check(0x03, 'bit string');
  offset += decodeLenBytes(buf, offset);
  check(0x00, '0 padding');
  return buf.sublist(offset);
}

/// ECDSA DER Signature
/// 0x30|b1|0x02|b2|r|0x02|b3|s
/// b1 = Length of remaining data
/// b2 = Length of r
/// b3 = Length of s
///
/// If the first byte is higher than 0x80, an additional 0x00 byte is prepended
/// to the value.
Uint8List bytesUnwrapDerSignature(Uint8List derEncoded) {
  if (derEncoded.length == 64) return derEncoded;

  final buf = Uint8List.fromList(derEncoded);

  const splitter = 0x02;
  final b1 = buf[1];

  if (b1 != buf.length - 2) {
    throw 'Bytes long is not correct';
  }
  if (buf[2] != splitter) {
    throw 'Splitter not found';
  }

  Tuple<int, Uint8List> getBytes(Uint8List remaining) {
    int length = 0;
    Uint8List bytes;

    if (remaining[0] != splitter) {
      throw 'Splitter not found';
    }
    if (remaining[1] > 32) {
      if (remaining[2] != 0x0 || remaining[3] <= 0x80) {
        throw 'r value is not correct';
      } else {
        length = remaining[1];
        bytes = remaining.sublist(3, 2 + length);
      }
    } else {
      length = remaining[1];
      bytes = remaining.sublist(2, 2 + length);
    }
    return Tuple(length, bytes);
  }

  final rRemaining = buf.sublist(2);
  final rBytes = getBytes(rRemaining);
  final b2 = rBytes.item1;
  final r = Uint8List.fromList(rBytes.item2);
  final sRemaining = rRemaining.sublist(b2 + 2);

  final sBytes = getBytes(sRemaining);
  // final b3 = sBytes.item1;
  final s = Uint8List.fromList(sBytes.item2);
  return Uint8List.fromList([...r, ...s]);
}

/// Wraps the given [payload] in a DER encoding tagged with the given encoded
/// [oid] like so: `SEQUENCE(oid, BITSTRING(payload))`
///
/// [payload] is the payload to encode as the bit string.
/// [oid] is the DER encoded (SEQUENCE wrapped) OID to tag the [payload] with.
Uint8List bytesWrapDer(Uint8List payload, Uint8List oid) {
  // The header needs to include the unused bit count byte in its length.
  final bitStringHeaderLength = 2 + encodeLenBytes(payload.lengthInBytes + 1);
  final len = oid.lengthInBytes + bitStringHeaderLength + payload.lengthInBytes;
  int offset = 0;
  final buf = Uint8List(1 + encodeLenBytes(len) + len);
  // Sequence.
  buf[offset++] = 0x30;
  // Sequence Length.
  offset += encodeLen(buf, offset, len);
  // OID.
  buf.setAll(offset, oid);
  offset += oid.lengthInBytes;
  // Bit String Header.
  buf[offset++] = 0x03;
  offset += encodeLen(buf, offset, payload.lengthInBytes + 1);
  // 0 padding.
  buf[offset++] = 0x00;
  buf.setAll(offset, Uint8List.fromList(payload));
  return buf;
}

Uint8List bytesWrapDerSignature(Uint8List rawSignature) {
  if (rawSignature.length != 64) {
    throw 'Raw signature length has to be length 64';
  }

  final r = rawSignature.sublist(0, 32);
  final s = rawSignature.sublist(32);

  Uint8List joinBytes(Uint8List arr) {
    if (arr[0] > 0x80) {
      return Uint8List.fromList([0x02, 0x21, 0x0, ...arr]);
    } else {
      return Uint8List.fromList([0x02, 0x20, ...arr]);
    }
  }

  final rBytes = joinBytes(r);
  final sBytes = joinBytes(s);

  final b1 = rBytes.length + sBytes.length;

  return Uint8List.fromList([0x30, b1, ...rBytes, ...sBytes]);
}

int decodeLenBytes(Uint8List buf, int offset) {
  if (buf[offset] < 0x80) {
    return 1;
  }
  if (buf[offset] == 0x80) {
    throw ArgumentError.value(buf[offset], 'length', 'Invalid length');
  }
  if (buf[offset] == 0x81) {
    return 2;
  }
  if (buf[offset] == 0x82) {
    return 3;
  }
  if (buf[offset] == 0x83) {
    return 4;
  }
  throw RangeError.range(
    buf[offset],
    null,
    0xffffff,
    'length',
    'Length is too long',
  );
}

int encodeLen(Uint8List buf, int offset, int len) {
  if (len <= 0x7f) {
    buf[offset] = len;
    return 1;
  } else if (len <= 0xff) {
    buf[offset] = 0x81;
    buf[offset + 1] = len;
    return 2;
  } else if (len <= 0xffff) {
    buf[offset] = 0x82;
    buf[offset + 1] = len >> 8;
    buf[offset + 2] = len;
    return 3;
  } else if (len <= 0xffffff) {
    buf[offset] = 0x83;
    buf[offset + 1] = len >> 16;
    buf[offset + 2] = len >> 8;
    buf[offset + 3] = len;
    return 4;
  }
  throw RangeError.range(len, null, 0xffffff, 'length', 'Length is too long');
}

int encodeLenBytes(int len) {
  if (len <= 0x7f) {
    return 1;
  } else if (len <= 0xff) {
    return 2;
  } else if (len <= 0xffff) {
    return 3;
  } else if (len <= 0xffffff) {
    return 4;
  }
  throw RangeError.range(len, null, 0xffffff, 'length', 'Length is too long');
}

bool isDerPublicKey(Uint8List pub, Uint8List oid) {
  final oidLength = oid.length;
  if (!pub.sublist(0, oidLength).eq(oid)) {
    return false;
  } else {
    try {
      return bytesWrapDer(bytesUnwrapDer(pub, oid), oid).eq(pub);
    } catch (e) {
      return false;
    }
  }
}

bool isDerSignature(Uint8List sig) {
  try {
    return bytesWrapDerSignature(bytesUnwrapDerSignature(sig)).eq(sig);
  } catch (e) {
    return false;
  }
}

extension U8aExtension on Uint8List {
  bool eq(Uint8List other) {
    bool equals(Object? e1, Object? e2) => e1 == e2;
    if (identical(this, other)) return true;
    var length = this.length;
    if (length != other.length) return false;
    for (var i = 0; i < length; i++) {
      if (!equals(this[i], other[i])) return false;
    }
    return true;
  }
}
