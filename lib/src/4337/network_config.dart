part of '../../account_abstraction_alchemy.dart';

/// Represents config for [SmartWalletFactory].
class NetworkConfig {
  /// The unique identifier of the chain.
  final int chainId;

  /// The URL of the block explorer for this chain.
  final String explorer;

  /// Gas policy id to be used for gas manager calls, obtained from Alchemy dashboard
  late final String gasPolicyId;

  /// The address of the EntryPoint contract on this chain.
  late EntryPointAddress entrypoint;

  /// The address of the AccountFactory contract on this chain.
  late EthereumAddress accountFactory;

  /// The URL of the JSON-RPC endpoint for this chain.
  late String jsonRpcUrl;

  /// The URL of the bundler service for this chain.
  late String bundlerUrl;

  /// The URL of the paymaster service for this chain.
  late String paymasterUrl;

  /// Smart account type
  late AccountType accountType;

  /// Creates a new instance of the [NetworkConfig] class.
  ///
  /// [chainId] is the unique identifier of the chain.
  /// [gasPolicyId] is unique gas policy id, obtained from Alchemy dashboard
  /// [explorer] is the URL of the block explorer for this chain.
  /// [entrypoint] is the address of the EntryPoint contract on this chain.
  /// [accountFactory] is the address of the AccountFactory contract on this
  ///   chain.
  /// [jsonRpcUrl] is the URL of the JSON-RPC endpoint for this chain.
  /// [bundlerUrl] is the URL of the bundler service for this chain.
  /// [paymasterUrl] is the optional URL of the paymaster service for this
  ///   chain.
  ///
  /// Example:
  ///
  /// ```dart
  /// final config = NetworkConfig(
  ///   chainId: 1,
  ///   explorer: 'https://etherscan.io',
  ///   entrypoint: EntryPointAddress('0x...'),
  ///   accountFactory: EthereumAddress('0x...'),
  ///   jsonRpcUrl: 'https://mainnet.infura.io/v3/...',
  ///   bundlerUrl: 'https://bundler.example.com',
  ///   paymasterUrl: 'https://paymaster.example.com',
  /// );
  /// ```

  NetworkConfig(
      {required this.chainId,
      required this.explorer,
      required this.jsonRpcUrl,
      required this.bundlerUrl,
      required this.paymasterUrl});
}

//predefined Chains you can use
class NetworkConfigs {
  static Map<Network, NetworkConfig> networks = {
    Network.ethereum: NetworkConfig(
        chainId: 1,
        explorer: 'https://etherscan.io/',
        jsonRpcUrl: 'https://eth-mainnet.g.alchemy.com/v2/',
        bundlerUrl: 'https://eth-mainnet.g.alchemy.com/v2/',
        paymasterUrl: 'https://eth-mainnet.g.alchemy.com/v2/'),
    Network.polygon: NetworkConfig(
      chainId: 137,
      explorer: 'https://polygonscan.com/',
      jsonRpcUrl: 'https://polygon-mainnet.g.alchemy.com/v2/',
      bundlerUrl: 'https://polygon-mainnet.g.alchemy.com/v2/',
      paymasterUrl: 'https://polygon-mainnet.g.alchemy.com/v2/',
    ),
    Network.sepolia: NetworkConfig(
      chainId: 11155111,
      explorer: 'https://sepolia.etherscan.io/',
      jsonRpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/',
      bundlerUrl: 'https://eth-sepolia.g.alchemy.com/v2/',
      paymasterUrl: 'https://eth-sepolia.g.alchemy.com/v2/',
    ),
    Network.polygonAmoy: NetworkConfig(
      chainId: 80002,
      explorer: 'https://amoy.polygonscan.com/',
      jsonRpcUrl: 'https://polygon-amoy.g.alchemy.com/v2/',
      bundlerUrl: 'https://polygon-amoy.g.alchemy.com/v2/',
      paymasterUrl: 'https://polygon-amoy.g.alchemy.com/v2/',
    ),
  };

  const NetworkConfigs._();

  /// Returns the [NetworkConfig] instance for the given [Network].
  ///
  /// [network] is the target network for which the [NetworkConfig] instance is required.
  /// [accountType] is type of alchemy account to create [AccountType]
  /// [version] is alchemy entry point contract version [EntryPointVersion]
  /// [alchemyApiKey] is alchemy API key obtained in Alchemy dashboard
  ///
  /// This method retrieves the [NetworkConfig] instance from a predefined map of
  /// networks and their corresponding chain configurations.
  ///
  /// Example:
  ///
  /// ```dart
  /// final chain = Chains.getChain(Network.ethereum, AccountType.simple, EntryPointVersion.v06, 'xxx-api-key');
  /// ```
  static NetworkConfig getConfig(
    Network network,
    AccountType accountType,
    EntryPointVersion version,
    String alchemyApiKey,
    String gasPolicyId,
  ) {
    if (version == EntryPointVersion.v07) {
      throw Exception('v.0.7 not yet implemented');
    }

    final originalNetwork = networks[network]!;
    final jsonRpcUrl = originalNetwork.jsonRpcUrl + alchemyApiKey;
    final bundlerUrl = originalNetwork.bundlerUrl + alchemyApiKey;
    final paymasterUrl = originalNetwork.paymasterUrl + alchemyApiKey;

    final NetworkConfig updatedNetwork = NetworkConfig(
      chainId: originalNetwork.chainId,
      explorer: originalNetwork.explorer,
      jsonRpcUrl: jsonRpcUrl,
      bundlerUrl: bundlerUrl,
      paymasterUrl: paymasterUrl,
    );

    updatedNetwork.entrypoint = (version == EntryPointVersion.v06)
        ? EntryPointAddress.v06
        : EntryPointAddress.v07;

    updatedNetwork.gasPolicyId = gasPolicyId;

    switch (accountType) {
      case AccountType.light:
        updatedNetwork.accountFactory =
            Constants.alchemyLightAccountFactoryAddress;
        break;
      case AccountType.simple:
        final networkMap =
            Constants.simpleAccountFactoryAddressesByNetwork[network];

        if (networkMap == null || networkMap[version] == null) {
          throw Exception(
              'Account factory address for given network is not defined'
              'please update network_config Constants class');
        }
        updatedNetwork.accountFactory = networkMap[version]!;
        break;
    }

    updatedNetwork.accountType = accountType;

    return updatedNetwork;
  }
}

/// Represents an EntryPoint contract version v0.6 or v0.7.
enum EntryPointVersion { v06, v07 }

/// Used to convert [EntryPointVersion] enum into double representing version.
extension EntryPointVersionExtension on EntryPointVersion {
  double get toDouble {
    switch (this) {
      case EntryPointVersion.v06:
        return 0.6;
      case EntryPointVersion.v07:
        return 0.7;
    }
  }
}

/// Represents the address of an EntryPoint contract.
class EntryPointAddress {
  /// Creates a new instance of the [EntryPointAddress] class.
  ///
  /// [version] is the version of the EntryPoint contract.
  /// [address] is the Ethereum address of the EntryPoint contract.
  /// The version of the EntryPoint contract.
  final double version;

  /// The Ethereum address of the EntryPoint contract.
  final EthereumAddress address;

  /// Returns the EntryPoint address for version 0.6 of the EntryPoint contract.
  static EntryPointAddress get v06 => EntryPointAddress(
        EntryPointVersion.v06.toDouble,
        Constants.alchemyEntryPointV06,
      );

  /// Returns the EntryPoint address for version 0.7 of the EntryPoint contract.
  static EntryPointAddress get v07 => EntryPointAddress(
        EntryPointVersion.v07.toDouble,
        Constants.alchemyEntryPointV07,
      );

  const EntryPointAddress(this.version, this.address);
}

enum Network {
  // mainnet
  ethereum,
  polygon,

  // testnet
  sepolia,
  polygonAmoy,
}
