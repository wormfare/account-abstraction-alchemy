part of 'interfaces.dart';

/// Abstract base class representing a provider for interacting with an entrypoint.
///
/// Implementations of this class are expected to provide functionality for interacting specifically
/// with bundlers and provides methods for sending user operations to an entrypoint.
abstract class BundlerProviderBase {
  /// Set of Ethereum RPC methods supported by a 4337 bundler.
  static final Set<String> methods = {
    'eth_chainId',
    'eth_getUserOperationReceipt',
    'eth_supportedEntryPoints',
    'eth_getUserOperationByHash',
    'eth_sendUserOperation',
    'eth_estimateUserOperationGas',
  };

  /// Asynchronously estimates the gas cost for a user operation using the provided data and entrypoint.
  ///
  /// Parameters:
  ///   - `userOp`: A map containing the user operation data.
  ///   - `entrypoint`: The [EntryPointAddress] representing the entrypoint for the operation.
  ///
  /// Returns:
  ///   A [Future] that completes with a [UserOperationGas] instance representing the estimated gas values.
  ///
  /// Example:
  /// ```dart
  /// var gasEstimation = await estimateUserOperationGas(
  ///   myUserOp, // Map<String, dynamic>
  ///   EthereumAddress.fromHex('0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789'),
  /// );
  /// ```
  /// This method uses the bundled RPC to estimate the gas cost for the provided user operation data.
  Future<UserOperationGas> estimateUserOperationGas(
      Map<String, dynamic> userOp, EntryPointAddress entrypoint);

  /// Asynchronously retrieves information about a user operation using its hash.
  /// This endpoint supports both v0.6 and v0.7 user operations,
  ///  and the response will include a user operation in one of the two formats
  ///  depending on which type of user operation is found
  ///  with the requested hash.
  ///
  /// Parameters:
  ///   - `userOpHash`: The hash of the user operation to retrieve information for.
  ///
  /// Returns:
  ///   A [Future] that completes with a [UserOperationByHash] instance representing the details of the user operation.
  ///
  /// Example:
  /// ```dart
  /// var userOpDetails = await getUserOperationByHash('0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef');
  /// ```
  /// This method uses the bundled RPC to fetch information about the specified user operation using its hash.
  Future<UserOperationByHash> getUserOperationByHash(String userOpHash);

  /// Asynchronously retrieves the receipt of a user operation using its hash.
  /// This endpoint supports both v0.6 and v0.7 user operations,
  ///  and the response will include a user operation in one of the two formats
  ///  depending on which type of user operation is found with
  ///  the requested hash.
  ///
  /// Parameters:
  ///   - `userOpHash`: The hash of the user operation to retrieve the receipt for.
  ///
  /// Returns:
  ///   A [Future] that completes with a [UserOperationReceipt] instance representing the receipt of the user operation.
  ///
  /// Example:
  /// ```dart
  /// var userOpReceipt = await getUserOpReceipt('0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef');
  /// ```
  /// This method uses the bundled RPC to fetch the receipt of the specified user operation using its hash.
  Future<UserOperationReceipt?> getUserOpReceipt(String userOpHash);

  /// Asynchronously sends a user operation to the bundler for execution.
  ///
  /// Parameters:
  ///   - `userOp`: A map containing the user operation data.
  ///   - `entrypoint`: The [EntryPointAddress] representing the entrypoint for the operation.
  ///
  /// Returns:
  ///   A [Future] that completes with a [UserOperationResponse] containing information about the executed operation.
  ///
  /// Example:
  /// ```dart
  /// var response = await sendUserOperation(
  ///   myUserOp, // Map<String, dynamic>
  ///   EthereumAddress.fromHex('0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789'),
  /// );
  /// ```
  /// This method uses the bundled RPC to send the specified user operation
  ///  for execution and returns the response.
  /// eth_sendUserOperation supports versions v0.6 and v0.7 of ERC-4337.
  /// These two versions define different formats for user operations,
  ///  and their entry point contracts are deployed at different addresses.
  ///  Thus, when calling eth_sendUserOperation, you must choose whether
  ///  you want to use the v0.6 or v0.7 version of this endpoint and ensure
  ///  that you are using the correct user operation format and entry point
  ///  address for that version.
  /// Which version you want is determined by the smart contract account
  ///  for which you are trying to send a user operation.
  ///  A given smart contract account will typically be written to be compatible
  ///  with either v0.6 or v0.7 and you should use that version in your request.
  ///  If you're not sure which version is compatible with a smart contract account,
  ///  you can look at its source code and check the first parameter to validateUserOp.
  ///  If it has type UserOperation, then the account uses v0.6, while if it has
  ///  type PackedUserOperation then the account uses v0.7.
  /// For more information about the differences in versions,
  /// see the specifications for ERC-4337 v0.6.0 and ERC-4337 v0.7.0,
  /// particularly the description of the user operation fields.
  ///
  /// You might get a "Replacement Underpriced Error" when using eth_sendUserOperation.
  ///  This error occurs when a user already has an existing operation in the mempool.
  ///  User operations can become "stuck" in the mempool if their gas fee
  ///  limits are too low to be included in a bundle.
  Future<UserOperationResponse> sendUserOperation(
      Map<String, dynamic> userOp, EntryPointAddress entrypoint);

  /// Asynchronously retrieves a list of supported entrypoints from the bundler.
  ///
  /// Returns:
  ///   A [Future] that completes with a list of supported entrypoints as strings.
  ///
  /// Example:
  /// ```dart
  /// var entrypoints = await supportedEntryPoints();
  /// ```
  ///
  /// Please note that the eth_supportedEntryPoints method returns an array
  ///  of supported entry points sorted by version, with the most
  ///  recent versions appearing first in the array.
  Future<List<String>> supportedEntryPoints();

  /// Validates if the provided method is a supported RPC method.
  ///
  /// Parameters:
  ///   - `method`: The Ethereum RPC method to validate.
  ///
  /// Throws:
  ///   - A [Exception] if the method is not a valid supported method.
  ///
  /// Example:
  /// ```dart
  /// validateBundlerMethod('eth_sendUserOperation');
  /// ```
  static validateBundlerMethod(String method) {
    assert(methods.contains(method), InvalidBundlerMethod(method));
  }
}
