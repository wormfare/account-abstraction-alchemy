part of '../../account_abstraction_alchemy.dart';

typedef Percent = double;

/// A class that represents gas settings for Ethereum transactions.
class GasSettings {
  /// The percentage by which the gas limits should be multiplied.
  ///
  /// This value should be between 0 and 100.
  Percent gasMultiplierPercentage;

  /// The user-defined maximum fee per gas for the transaction.
  BigInt? userDefinedMaxFeePerGas;

  /// The user-defined maximum priority fee per gas for the transaction.
  BigInt? userDefinedMaxPriorityFeePerGas;

  /// Creates a new instance of the [GasSettings] class.
  ///
  /// [gasMultiplierPercentage] is the percentage by which the gas limits should be multiplied.
  /// Defaults to 0.
  ///
  /// [userDefinedMaxFeePerGas] is the user-defined maximum fee per gas for the transaction.
  ///
  /// [userDefinedMaxPriorityFeePerGas] is the user-defined maximum priority fee per gas for the transaction.
  ///
  /// An assertion is made to ensure that [gasMultiplierPercentage] is between 0 and 100.
  GasSettings({
    this.gasMultiplierPercentage = 0,
    this.userDefinedMaxFeePerGas,
    this.userDefinedMaxPriorityFeePerGas,
  }) : assert(gasMultiplierPercentage >= 0,
            RangeOutOfBounds('Wrong Gas multiplier percentage', 0, 100));
}

/// A mixin that provides methods for managing gas settings for user operations.
mixin _GasSettings {
  /// The gas settings for user operations.
  GasSettings _gasParams = GasSettings();

  /// Sets the gas settings for user operations.
  ///
  /// [gasParams] is an instance of the [GasSettings] class containing the gas settings.
  set gasSettings(GasSettings gasParams) => _gasParams = gasParams;

  /// Applies the gas settings to a user operation, by multiplying the gas limits by a certain percentage.
  ///
  /// [op] is the user operation to which the gas settings should be applied.
  ///
  /// Returns a new [UserOperation] object with the updated gas settings.
  UserOperation applyCustomGasSettings(UserOperation op, double version) {
    final multiplier = _gasParams.gasMultiplierPercentage / 100 + 1;

    return op.copyWith(
        version: version,
        callGasLimit: BigInt.from(op.callGasLimit.toDouble() * multiplier),
        verificationGasLimit:
            BigInt.from(op.verificationGasLimit.toDouble() * multiplier),
        preVerificationGas:
            BigInt.from(op.preVerificationGas.toDouble() * multiplier),
        maxFeePerGas: _gasParams.userDefinedMaxFeePerGas,
        maxPriorityFeePerGas: _gasParams.userDefinedMaxPriorityFeePerGas);
  }
}

/// Used to manage the plugins used in the [Smartwallet] instance
mixin _PluginManager {
  final Map<String, dynamic> _plugins = {};

  ///returns a list of all active plugins
  List<String> activePlugins() {
    return _plugins.keys.toList(growable: false);
  }

  /// Adds a plugin by name.
  ///
  /// Parameters:
  ///   - `name`: The name of the plugin to add.
  ///   - `module`: The instance of the plugin.
  ///
  /// Example:
  /// ```dart
  /// addPlugin('logger', Logger());
  /// ```
  void addPlugin<T>(String name, T module) {
    _plugins[name] = module;
  }

  /// checks if a plugin exists
  ///
  /// Parameters:
  ///   - `name`: The name of the plugin to check
  ///
  /// Returns:
  ///   true if the plugin exists
  bool hasPlugin(String name) {
    return _plugins.containsKey(name);
  }

  /// Gets a plugin by name.
  ///
  /// Parameters:
  ///   - `name`: Optional. The name of the plugin to retrieve.
  ///
  /// Returns:
  ///   The plugin with the specified name.
  T plugin<T>([String? name]) {
    if (name == null) {
      for (var plugin in _plugins.values) {
        if (plugin is T) {
          return plugin;
        }
      }
    }
    return _plugins[name] as T;
  }

  /// Removes an unwanted plugin by name.
  ///
  /// Parameters:
  ///   - `name`: The name of the plugin to remove.
  ///
  /// Example:
  /// ```dart
  /// removePlugin('logger');
  /// ```
  void removePlugin(String name) {
    _plugins.remove(name);
  }
}
