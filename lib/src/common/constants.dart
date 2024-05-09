part of '../../account_abstraction_alchemy.dart';

class Constants {
  static EthereumAddress alchemyEntryPointV06 =
      EthereumAddress.fromHex('0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789');
  static EthereumAddress alchemyEntryPointV07 =
      EthereumAddress.fromHex('0x0000000071727De22E5E9d8BAf0edAc6f37da032');
  static EthereumAddress zeroAddress =
      EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');
  static final EthereumAddress alchemySimpleAccountFactoryAddressV06 =
      EthereumAddress.fromHex('0x15Ba39375ee2Ab563E8873C8390be6f2E2F50232');
  static final EthereumAddress alchemySimpleAccountFactoryAddressV06SEPOLIA =
      EthereumAddress.fromHex('0x9406cc6185a346906296840746125a0e44976454');
  static final EthereumAddress alchemySimpleAccountFactoryAddressV07 =
      EthereumAddress.fromHex('0x91E60e0613810449d098b0b5Ec8b51A0FE8c8985');
  static final EthereumAddress alchemyLightAccountFactoryAddress =
      EthereumAddress.fromHex('0x00004EC70002a32400f8ae005A26081065620D20');
  static const String dummySignature =
      '0xfffffffffffffffffffffffffffffff0000000000000000000000000000000007'
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c';

  static final Map<Network, Map<EntryPointVersion, EthereumAddress>>
      simpleAccountFactoryAddressesByNetwork = {
    Network.ethereum: {
      EntryPointVersion.v06: alchemySimpleAccountFactoryAddressV06,
      EntryPointVersion.v07: alchemySimpleAccountFactoryAddressV07,
    },
    Network.polygon: {
      EntryPointVersion.v06: alchemySimpleAccountFactoryAddressV06,
      EntryPointVersion.v07: alchemySimpleAccountFactoryAddressV07,
    },
    Network.sepolia: {
      EntryPointVersion.v06: alchemySimpleAccountFactoryAddressV06SEPOLIA,
      EntryPointVersion.v07: alchemySimpleAccountFactoryAddressV07,
    }
  };
}
