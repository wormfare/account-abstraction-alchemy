part of 'interfaces.dart';

abstract class SmartWalletFactoryBase {
  /// Creates a new simple account with the provided salt.
  ///
  /// [salt] is the salt value used in the account creation process.
  ///
  /// Returns a [Future] that resolves to a [SmartWallet] instance representing
  /// the created simple account.
  Future<SmartWallet> createSimpleAccount(Uint256 salt);

  /// Creates a new light account with the provided salt.
  ///
  /// [salt] is the salt value used in the account creation process.
  ///
  /// Returns a [Future] that resolves to a [SmartWallet] instance representing
  /// the created light account.
  Future<SmartWallet> createLightAccount(Uint256 salt);
}
