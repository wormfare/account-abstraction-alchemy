part of '../../account_abstraction_alchemy.dart';

class PrivateKeySigner implements SingerInterface {
  late final Wallet _credential;

  @override
  String dummySignature = Constants.dummySignature;

  /// Creates a PrivateKeySigner instance using the provided EthPrivateKey.
  ///
  /// Parameters:
  /// - [privateKey]: The EthPrivateKey used to create the PrivateKeySigner.
  /// - [password]: The password for encrypting the private key.
  /// - [random]: The Random instance for generating random values.
  /// - [scryptN]: Scrypt parameter N (CPU/memory cost) for key derivation. Defaults to 8192.
  /// - [p]: Scrypt parameter p (parallelization factor) for key derivation. Defaults to 1.
  ///
  /// Example:
  /// ```dart
  /// final ethPrivateKey = EthPrivateKey.fromHex('your_private_key_hex');
  /// final password = 'your_password';
  /// final random = Random.secure();
  /// final privateKeySigner = PrivateKeySigner.create(ethPrivateKey, password, random);
  /// ```
  PrivateKeySigner.create(EthPrivateKey privateKey,
      {int scryptN = 8192, int p = 1}) {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final password = base64Url.encode(bytes);

    _credential =
        Wallet.createNew(privateKey, password, random, scryptN: scryptN, p: p);
  }

  /// Creates a PrivateKeySigner instance from JSON representation.
  ///
  /// Parameters:
  /// - [source]: The JSON representation of the wallet.
  /// - [password]: The password for decrypting the private key.
  ///
  /// Example:
  /// ```dart
  /// final sourceJson = '{"privateKey": "your_private_key_encrypted", ...}';
  /// final password = 'your_password';
  /// final privateKeySigner = PrivateKeySigner.fromJson(sourceJson, password);
  /// ```
  factory PrivateKeySigner.fromJson(String source, String password) =>
      PrivateKeySigner._internal(
        Wallet.fromJson(source, password),
      );

  PrivateKeySigner._internal(this._credential);

  /// Returns the Ethereum address associated with the PrivateKeySigner.
  EthereumAddress get address => _credential.privateKey.address;

  /// Returns the public key associated with the PrivateKeySigner.
  Uint8List get publicKey => _credential.privateKey.encodedPublicKey;

  @override
  String getAddress() {
    return address.hex;
  }

  @override
  Future<Uint8List> personalSign(Uint8List hash) async {
    return _credential.privateKey.signPersonalMessageToUint8List(hash);
  }

  @override
  Future<MsgSignature> signToEc(Uint8List hash) async {
    return _credential.privateKey.signToEcSignature(hash);
  }

  String toJson() => _credential.toJson();
}
