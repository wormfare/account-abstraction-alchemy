part of 'interfaces.dart';

abstract class PaymasterBase {
  /// Sets the address of the Paymaster.
  ///
  /// [address] is the address of the Paymaster.
  set paymasterAddress(EthereumAddress? address);

  /// Intercepts a [UserOperation] and sponsors it with the Paymaster.
  ///
  /// [operation] is the [UserOperation] to be sponsored.
  ///
  /// Returns a [Future] that resolves to the sponsored [UserOperation].
  ///
  /// This method calls the `sponsorUserOperation` method to get the Paymaster
  /// response, and then creates a new [UserOperation] with the updated
  /// Paymaster data and gas limits.
  Future<UserOperation> intercept(UserOperation operation);

  /// Sponsors a user operation with the Paymaster.
  ///
  /// [userOp] is a map containing the user operation data.
  /// [entrypoint] is the address of the EntryPoint contract.
  ///
  /// Returns a [Future] that resolves to a [PaymasterResponse] containing the
  /// Paymaster data and gas limits for the sponsored user operation.
  ///
  /// This method calls the `alchemy_requestGasAndPaymasterAndData` RPC method on the Paymaster
  /// contract to get full gas data.
  Future<PaymasterResponse> requestGasAndPaymasterAndData(
    Map<String, dynamic> userOp,
    EntryPointAddress entrypoint,
  );
}
