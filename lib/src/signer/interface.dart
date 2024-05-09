part of '../../account_abstraction_alchemy.dart';

typedef Signer = SingerInterface;

/// An interface for a signer, allowing signing of data and returning the result.
///
/// signer interface provides an interface for accessing signer address and signing
/// messages in the Ethereum context.
abstract class SingerInterface {
  /// The dummy signature is a valid signature that can be used for transactions
  /// which require signatures, but accept dummy signature
  String dummySignature = Constants.dummySignature;

  /// Generates an Ethereum address of the signer.
  ///
  /// Example:
  /// ```dart
  /// final address = getAddress();
  /// ```
  String getAddress();

  /// Signs the provided [hash] using the personal sign method.
  ///
  /// Parameters:
  /// - [hash]: The hash to be signed.
  ///
  /// Example:
  /// ```dart
  /// final hash = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
  /// final signature = await personalSign(hash); // assuming no data is required for actual signing
  /// ```

  Future<Uint8List> personalSign(Uint8List hash);

  /// Signs the provided [hash] using elliptic curve (EC) signatures and returns the r and s values.
  ///
  /// Parameters:
  /// - [hash]: The hash to be signed.
  ///
  /// Example:
  /// ```dart
  /// final hash = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
  /// final signature = await signToEc(hash);
  /// ```
  Future<MsgSignature> signToEc(Uint8List hash);
}
