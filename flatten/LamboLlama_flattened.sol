// SPDX-License-Identifier: LZBL-1.2 AND MIT

// File @layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity >=0.8.0;

struct SetConfigParam {
    uint32 eid;
    uint32 configType;
    bytes config;
}

interface IMessageLibManager {
    struct Timeout {
        address lib;
        uint256 expiry;
    }

    event LibraryRegistered(address newLib);
    event DefaultSendLibrarySet(uint32 eid, address newLib);
    event DefaultReceiveLibrarySet(uint32 eid, address newLib);
    event DefaultReceiveLibraryTimeoutSet(uint32 eid, address oldLib, uint256 expiry);
    event SendLibrarySet(address sender, uint32 eid, address newLib);
    event ReceiveLibrarySet(address receiver, uint32 eid, address newLib);
    event ReceiveLibraryTimeoutSet(address receiver, uint32 eid, address oldLib, uint256 timeout);

    function registerLibrary(address _lib) external;

    function isRegisteredLibrary(address _lib) external view returns (bool);

    function getRegisteredLibraries() external view returns (address[] memory);

    function setDefaultSendLibrary(uint32 _eid, address _newLib) external;

    function defaultSendLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibrary(uint32 _eid, address _newLib, uint256 _gracePeriod) external;

    function defaultReceiveLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibraryTimeout(uint32 _eid, address _lib, uint256 _expiry) external;

    function defaultReceiveLibraryTimeout(
        uint32 _eid
    ) external view returns (address lib, uint256 expiry);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    function isValidReceiveLibrary(
        address _receiver,
        uint32 _eid,
        address _lib
    ) external view returns (bool);

    /// ------------------- OApp interfaces -------------------
    function setSendLibrary(address _oapp, uint32 _eid, address _newLib) external;

    function getSendLibrary(address _sender, uint32 _eid) external view returns (address lib);

    function isDefaultSendLibrary(address _sender, uint32 _eid) external view returns (bool);

    function setReceiveLibrary(
        address _oapp,
        uint32 _eid,
        address _newLib,
        uint256 _gracePeriod
    ) external;

    function getReceiveLibrary(
        address _receiver,
        uint32 _eid
    ) external view returns (address lib, bool isDefault);

    function setReceiveLibraryTimeout(
        address _oapp,
        uint32 _eid,
        address _lib,
        uint256 _expiry
    ) external;

    function receiveLibraryTimeout(
        address _receiver,
        uint32 _eid
    ) external view returns (address lib, uint256 expiry);

    function setConfig(address _oapp, address _lib, SetConfigParam[] calldata _params) external;

    function getConfig(
        address _oapp,
        address _lib,
        uint32 _eid,
        uint32 _configType
    ) external view returns (bytes memory config);
}

// File @layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessagingChannel.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingChannel {
    event InboundNonceSkipped(uint32 srcEid, bytes32 sender, address receiver, uint64 nonce);
    event PacketNilified(
        uint32 srcEid,
        bytes32 sender,
        address receiver,
        uint64 nonce,
        bytes32 payloadHash
    );
    event PacketBurnt(
        uint32 srcEid,
        bytes32 sender,
        address receiver,
        uint64 nonce,
        bytes32 payloadHash
    );

    function eid() external view returns (uint32);

    // this is an emergency function if a message cannot be verified for some reasons
    // required to provide _nextNonce to avoid race condition
    function skip(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce) external;

    function nilify(
        address _oapp,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce,
        bytes32 _payloadHash
    ) external;

    function burn(
        address _oapp,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce,
        bytes32 _payloadHash
    ) external;

    function nextGuid(
        address _sender,
        uint32 _dstEid,
        bytes32 _receiver
    ) external view returns (bytes32);

    function inboundNonce(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender
    ) external view returns (uint64);

    function outboundNonce(
        address _sender,
        uint32 _dstEid,
        bytes32 _receiver
    ) external view returns (uint64);

    function inboundPayloadHash(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external view returns (bytes32);

    function lazyInboundNonce(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender
    ) external view returns (uint64);
}

// File @layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessagingComposer.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingComposer {
    event ComposeSent(address from, address to, bytes32 guid, uint16 index, bytes message);
    event ComposeDelivered(address from, address to, bytes32 guid, uint16 index);
    event LzComposeAlert(
        address indexed from,
        address indexed to,
        address indexed executor,
        bytes32 guid,
        uint16 index,
        uint256 gas,
        uint256 value,
        bytes message,
        bytes extraData,
        bytes reason
    );

    function composeQueue(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index
    ) external view returns (bytes32 messageHash);

    function sendCompose(
        address _to,
        bytes32 _guid,
        uint16 _index,
        bytes calldata _message
    ) external;

    function lzCompose(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable;
}

// File @layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessagingContext.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingContext {
    function isSendingMessage() external view returns (bool);

    function getSendContext() external view returns (uint32 dstEid, address sender);
}

// File @layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity >=0.8.0;

struct MessagingParams {
    uint32 dstEid;
    bytes32 receiver;
    bytes message;
    bytes options;
    bool payInLzToken;
}

struct MessagingReceipt {
    bytes32 guid;
    uint64 nonce;
    MessagingFee fee;
}

struct MessagingFee {
    uint256 nativeFee;
    uint256 lzTokenFee;
}

struct Origin {
    uint32 srcEid;
    bytes32 sender;
    uint64 nonce;
}

interface ILayerZeroEndpointV2 is
    IMessageLibManager,
    IMessagingComposer,
    IMessagingChannel,
    IMessagingContext
{
    event PacketSent(bytes encodedPayload, bytes options, address sendLibrary);

    event PacketVerified(Origin origin, address receiver, bytes32 payloadHash);

    event PacketDelivered(Origin origin, address receiver);

    event LzReceiveAlert(
        address indexed receiver,
        address indexed executor,
        Origin origin,
        bytes32 guid,
        uint256 gas,
        uint256 value,
        bytes message,
        bytes extraData,
        bytes reason
    );

    event LzTokenSet(address token);

    event DelegateSet(address sender, address delegate);

    function quote(
        MessagingParams calldata _params,
        address _sender
    ) external view returns (MessagingFee memory);

    function send(
        MessagingParams calldata _params,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory);

    function verify(Origin calldata _origin, address _receiver, bytes32 _payloadHash) external;

    function verifiable(Origin calldata _origin, address _receiver) external view returns (bool);

    function initializable(
        Origin calldata _origin,
        address _receiver
    ) external view returns (bool);

    function lzReceive(
        Origin calldata _origin,
        address _receiver,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable;

    // oapp can burn messages partially by calling this function with its own business logic if messages are verified in order
    function clear(
        address _oapp,
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message
    ) external;

    function setLzToken(address _lzToken) external;

    function lzToken() external view returns (address);

    function nativeToken() external view returns (address);

    function setDelegate(address _delegate) external;
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppCore.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title IOAppCore
 */
interface IOAppCore {
    // Custom error messages
    error OnlyPeer(uint32 eid, bytes32 sender);
    error NoPeer(uint32 eid);
    error InvalidEndpointCall();
    error InvalidDelegate();

    // Event emitted when a peer (OApp) is set for a corresponding endpoint
    event PeerSet(uint32 eid, bytes32 peer);

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol contract.
     * @return receiverVersion The version of the OAppReceiver.sol contract.
     */
    function oAppVersion() external view returns (uint64 senderVersion, uint64 receiverVersion);

    /**
     * @notice Retrieves the LayerZero endpoint associated with the OApp.
     * @return iEndpoint The LayerZero endpoint as an interface.
     */
    function endpoint() external view returns (ILayerZeroEndpointV2 iEndpoint);

    /**
     * @notice Retrieves the peer (OApp) associated with a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @return peer The peer address (OApp instance) associated with the corresponding endpoint.
     */
    function peers(uint32 _eid) external view returns (bytes32 peer);

    /**
     * @notice Sets the peer address (OApp instance) for a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @param _peer The address of the peer to be associated with the corresponding endpoint.
     */
    function setPeer(uint32 _eid, bytes32 _peer) external;

    /**
     * @notice Sets the delegate address for the OApp Core.
     * @param _delegate The address of the delegate to be set.
     */
    function setDelegate(address _delegate) external;
}

// File @layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroReceiver.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity >=0.8.0;

interface ILayerZeroReceiver {
    function allowInitializePath(Origin calldata _origin) external view returns (bool);

    function nextNonce(uint32 _eid, bytes32 _sender) external view returns (uint64);

    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable;
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppReceiver.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

interface IOAppReceiver is ILayerZeroReceiver {
    /**
     * @notice Indicates whether an address is an approved composeMsg sender to the Endpoint.
     * @param _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @param _message The lzReceive payload.
     * @param _sender The sender address.
     * @return isSender Is a valid sender.
     *
     * @dev Applications can optionally choose to implement a separate composeMsg sender that is NOT the bridging layer.
     * @dev The default sender IS the OAppReceiver implementer.
     */
    function isComposeMsgSender(
        Origin calldata _origin,
        bytes calldata _message,
        address _sender
    ) external view returns (bool isSender);
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppOptionsType3.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Struct representing enforced option parameters.
 */
struct EnforcedOptionParam {
    uint32 eid; // Endpoint ID
    uint16 msgType; // Message Type
    bytes options; // Additional options
}

/**
 * @title IOAppOptionsType3
 * @dev Interface for the OApp with Type 3 Options, allowing the setting and combining of enforced options.
 */
interface IOAppOptionsType3 {
    // Custom error message for invalid options
    error InvalidOptions(bytes options);

    // Event emitted when enforced options are set
    event EnforcedOptionSet(EnforcedOptionParam[] _enforcedOptions);

    /**
     * @notice Sets enforced options for specific endpoint and message type combinations.
     * @param _enforcedOptions An array of EnforcedOptionParam structures specifying enforced options.
     */
    function setEnforcedOptions(EnforcedOptionParam[] calldata _enforcedOptions) external;

    /**
     * @notice Combines options for a given endpoint and message type.
     * @param _eid The endpoint ID.
     * @param _msgType The OApp message type.
     * @param _extraOptions Additional options passed by the caller.
     * @return options The combination of caller specified options AND enforced options.
     */
    function combineOptions(
        uint32 _eid,
        uint16 _msgType,
        bytes calldata _extraOptions
    ) external view returns (bytes memory options);
}

// File @openzeppelin/contracts/utils/Context.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File @openzeppelin/contracts/access/Ownable.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OAppOptionsType3.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title OAppOptionsType3
 * @dev Abstract contract implementing the IOAppOptionsType3 interface with type 3 options.
 */
abstract contract OAppOptionsType3 is IOAppOptionsType3, Ownable {
    uint16 internal constant OPTION_TYPE_3 = 3;

    // @dev The "msgType" should be defined in the child contract.
    mapping(uint32 eid => mapping(uint16 msgType => bytes enforcedOption)) public enforcedOptions;

    /**
     * @dev Sets the enforced options for specific endpoint and message type combinations.
     * @param _enforcedOptions An array of EnforcedOptionParam structures specifying enforced options.
     *
     * @dev Only the owner/admin of the OApp can call this function.
     * @dev Provides a way for the OApp to enforce things like paying for PreCrime, AND/OR minimum dst lzReceive gas amounts etc.
     * @dev These enforced options can vary as the potential options/execution on the remote may differ as per the msgType.
     * eg. Amount of lzReceive() gas necessary to deliver a lzCompose() message adds overhead you dont want to pay
     * if you are only making a standard LayerZero message ie. lzReceive() WITHOUT sendCompose().
     */
    function setEnforcedOptions(
        EnforcedOptionParam[] calldata _enforcedOptions
    ) public virtual onlyOwner {
        _setEnforcedOptions(_enforcedOptions);
    }

    /**
     * @dev Sets the enforced options for specific endpoint and message type combinations.
     * @param _enforcedOptions An array of EnforcedOptionParam structures specifying enforced options.
     *
     * @dev Provides a way for the OApp to enforce things like paying for PreCrime, AND/OR minimum dst lzReceive gas amounts etc.
     * @dev These enforced options can vary as the potential options/execution on the remote may differ as per the msgType.
     * eg. Amount of lzReceive() gas necessary to deliver a lzCompose() message adds overhead you dont want to pay
     * if you are only making a standard LayerZero message ie. lzReceive() WITHOUT sendCompose().
     */
    function _setEnforcedOptions(EnforcedOptionParam[] memory _enforcedOptions) internal virtual {
        for (uint256 i = 0; i < _enforcedOptions.length; i++) {
            // @dev Enforced options are only available for optionType 3, as type 1 and 2 dont support combining.
            _assertOptionsType3(_enforcedOptions[i].options);
            enforcedOptions[_enforcedOptions[i].eid][
                _enforcedOptions[i].msgType
            ] = _enforcedOptions[i].options;
        }

        emit EnforcedOptionSet(_enforcedOptions);
    }

    /**
     * @notice Combines options for a given endpoint and message type.
     * @param _eid The endpoint ID.
     * @param _msgType The OAPP message type.
     * @param _extraOptions Additional options passed by the caller.
     * @return options The combination of caller specified options AND enforced options.
     *
     * @dev If there is an enforced lzReceive option:
     * - {gasLimit: 200k, msg.value: 1 ether} AND a caller supplies a lzReceive option: {gasLimit: 100k, msg.value: 0.5 ether}
     * - The resulting options will be {gasLimit: 300k, msg.value: 1.5 ether} when the message is executed on the remote lzReceive() function.
     * @dev This presence of duplicated options is handled off-chain in the verifier/executor.
     */
    function combineOptions(
        uint32 _eid,
        uint16 _msgType,
        bytes calldata _extraOptions
    ) public view virtual returns (bytes memory) {
        bytes memory enforced = enforcedOptions[_eid][_msgType];

        // No enforced options, pass whatever the caller supplied, even if it's empty or legacy type 1/2 options.
        if (enforced.length == 0) return _extraOptions;

        // No caller options, return enforced
        if (_extraOptions.length == 0) return enforced;

        // @dev If caller provided _extraOptions, must be type 3 as its the ONLY type that can be combined.
        if (_extraOptions.length >= 2) {
            _assertOptionsType3(_extraOptions);
            // @dev Remove the first 2 bytes containing the type from the _extraOptions and combine with enforced.
            return bytes.concat(enforced, _extraOptions[2:]);
        }

        // No valid set of options was found.
        revert InvalidOptions(_extraOptions);
    }

    /**
     * @dev Internal function to assert that options are of type 3.
     * @param _options The options to be checked.
     */
    function _assertOptionsType3(bytes memory _options) internal pure virtual {
        uint16 optionsType;
        assembly {
            optionsType := mload(add(_options, 2))
        }
        if (optionsType != OPTION_TYPE_3) revert InvalidOptions(_options);
    }
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppCore.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title OAppCore
 * @dev Abstract contract implementing the IOAppCore interface with basic OApp configurations.
 */
abstract contract OAppCore is IOAppCore, Ownable {
    // The LayerZero endpoint associated with the given OApp
    ILayerZeroEndpointV2 public immutable endpoint;

    // Mapping to store peers associated with corresponding endpoints
    mapping(uint32 eid => bytes32 peer) public peers;

    /**
     * @dev Constructor to initialize the OAppCore with the provided endpoint and delegate.
     * @param _endpoint The address of the LOCAL Layer Zero endpoint.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     *
     * @dev The delegate typically should be set as the owner of the contract.
     */
    constructor(address _endpoint, address _delegate) {
        endpoint = ILayerZeroEndpointV2(_endpoint);

        if (_delegate == address(0)) revert InvalidDelegate();
        endpoint.setDelegate(_delegate);
    }

    /**
     * @notice Sets the peer address (OApp instance) for a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @param _peer The address of the peer to be associated with the corresponding endpoint.
     *
     * @dev Only the owner/admin of the OApp can call this function.
     * @dev Indicates that the peer is trusted to send LayerZero messages to this OApp.
     * @dev Set this to bytes32(0) to remove the peer address.
     * @dev Peer is a bytes32 to accommodate non-evm chains.
     */
    function setPeer(uint32 _eid, bytes32 _peer) public virtual onlyOwner {
        _setPeer(_eid, _peer);
    }

    /**
     * @notice Sets the peer address (OApp instance) for a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @param _peer The address of the peer to be associated with the corresponding endpoint.
     *
     * @dev Indicates that the peer is trusted to send LayerZero messages to this OApp.
     * @dev Set this to bytes32(0) to remove the peer address.
     * @dev Peer is a bytes32 to accommodate non-evm chains.
     */
    function _setPeer(uint32 _eid, bytes32 _peer) internal virtual {
        peers[_eid] = _peer;
        emit PeerSet(_eid, _peer);
    }

    /**
     * @notice Internal function to get the peer address associated with a specific endpoint; reverts if NOT set.
     * ie. the peer is set to bytes32(0).
     * @param _eid The endpoint ID.
     * @return peer The address of the peer associated with the specified endpoint.
     */
    function _getPeerOrRevert(uint32 _eid) internal view virtual returns (bytes32) {
        bytes32 peer = peers[_eid];
        if (peer == bytes32(0)) revert NoPeer(_eid);
        return peer;
    }

    /**
     * @notice Sets the delegate address for the OApp.
     * @param _delegate The address of the delegate to be set.
     *
     * @dev Only the owner/admin of the OApp can call this function.
     * @dev Provides the ability for a delegate to set configs, on behalf of the OApp, directly on the Endpoint contract.
     */
    function setDelegate(address _delegate) public onlyOwner {
        endpoint.setDelegate(_delegate);
    }
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppReceiver.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title OAppReceiver
 * @dev Abstract contract implementing the ILayerZeroReceiver interface and extending OAppCore for OApp receivers.
 */
abstract contract OAppReceiver is IOAppReceiver, OAppCore {
    // Custom error message for when the caller is not the registered endpoint/
    error OnlyEndpoint(address addr);

    // @dev The version of the OAppReceiver implementation.
    // @dev Version is bumped when changes are made to this contract.
    uint64 internal constant RECEIVER_VERSION = 2;

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol contract.
     * @return receiverVersion The version of the OAppReceiver.sol contract.
     *
     * @dev Providing 0 as the default for OAppSender version. Indicates that the OAppSender is not implemented.
     * ie. this is a RECEIVE only OApp.
     * @dev If the OApp uses both OAppSender and OAppReceiver, then this needs to be override returning the correct versions.
     */
    function oAppVersion()
        public
        view
        virtual
        returns (uint64 senderVersion, uint64 receiverVersion)
    {
        return (0, RECEIVER_VERSION);
    }

    /**
     * @notice Indicates whether an address is an approved composeMsg sender to the Endpoint.
     * @dev _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @dev _message The lzReceive payload.
     * @param _sender The sender address.
     * @return isSender Is a valid sender.
     *
     * @dev Applications can optionally choose to implement separate composeMsg senders that are NOT the bridging layer.
     * @dev The default sender IS the OAppReceiver implementer.
     */
    function isComposeMsgSender(
        Origin calldata /*_origin*/,
        bytes calldata /*_message*/,
        address _sender
    ) public view virtual returns (bool) {
        return _sender == address(this);
    }

    /**
     * @notice Checks if the path initialization is allowed based on the provided origin.
     * @param origin The origin information containing the source endpoint and sender address.
     * @return Whether the path has been initialized.
     *
     * @dev This indicates to the endpoint that the OApp has enabled msgs for this particular path to be received.
     * @dev This defaults to assuming if a peer has been set, its initialized.
     * Can be overridden by the OApp if there is other logic to determine this.
     */
    function allowInitializePath(Origin calldata origin) public view virtual returns (bool) {
        return peers[origin.srcEid] == origin.sender;
    }

    /**
     * @notice Retrieves the next nonce for a given source endpoint and sender address.
     * @dev _srcEid The source endpoint ID.
     * @dev _sender The sender address.
     * @return nonce The next nonce.
     *
     * @dev The path nonce starts from 1. If 0 is returned it means that there is NO nonce ordered enforcement.
     * @dev Is required by the off-chain executor to determine the OApp expects msg execution is ordered.
     * @dev This is also enforced by the OApp.
     * @dev By default this is NOT enabled. ie. nextNonce is hardcoded to return 0.
     */
    function nextNonce(
        uint32 /*_srcEid*/,
        bytes32 /*_sender*/
    ) public view virtual returns (uint64 nonce) {
        return 0;
    }

    /**
     * @dev Entry point for receiving messages or packets from the endpoint.
     * @param _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @param _guid The unique identifier for the received LayerZero message.
     * @param _message The payload of the received message.
     * @param _executor The address of the executor for the received message.
     * @param _extraData Additional arbitrary data provided by the corresponding executor.
     *
     * @dev Entry point for receiving msg/packet from the LayerZero endpoint.
     */
    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) public payable virtual {
        // Ensures that only the endpoint can attempt to lzReceive() messages to this OApp.
        if (address(endpoint) != msg.sender) revert OnlyEndpoint(msg.sender);

        // Ensure that the sender matches the expected peer for the source endpoint.
        if (_getPeerOrRevert(_origin.srcEid) != _origin.sender)
            revert OnlyPeer(_origin.srcEid, _origin.sender);

        // Call the internal OApp implementation of lzReceive.
        _lzReceive(_origin, _guid, _message, _executor, _extraData);
    }

    /**
     * @dev Internal function to implement lzReceive logic without needing to copy the basic parameter validation.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual;
}

// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File @openzeppelin/contracts/utils/Address.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value)
        );
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value)
            );
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        require(
            returndata.length == 0 || abi.decode(returndata, (bool)),
            "SafeERC20: ERC20 operation did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool))) &&
            Address.isContract(address(token));
    }
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OAppSender.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title OAppSender
 * @dev Abstract contract implementing the OAppSender functionality for sending messages to a LayerZero endpoint.
 */
abstract contract OAppSender is OAppCore {
    using SafeERC20 for IERC20;

    // Custom error messages
    error NotEnoughNative(uint256 msgValue);
    error LzTokenUnavailable();

    // @dev The version of the OAppSender implementation.
    // @dev Version is bumped when changes are made to this contract.
    uint64 internal constant SENDER_VERSION = 1;

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol contract.
     * @return receiverVersion The version of the OAppReceiver.sol contract.
     *
     * @dev Providing 0 as the default for OAppReceiver version. Indicates that the OAppReceiver is not implemented.
     * ie. this is a SEND only OApp.
     * @dev If the OApp uses both OAppSender and OAppReceiver, then this needs to be override returning the correct versions
     */
    function oAppVersion()
        public
        view
        virtual
        returns (uint64 senderVersion, uint64 receiverVersion)
    {
        return (SENDER_VERSION, 0);
    }

    /**
     * @dev Internal function to interact with the LayerZero EndpointV2.quote() for fee calculation.
     * @param _dstEid The destination endpoint ID.
     * @param _message The message payload.
     * @param _options Additional options for the message.
     * @param _payInLzToken Flag indicating whether to pay the fee in LZ tokens.
     * @return fee The calculated MessagingFee for the message.
     *      - nativeFee: The native fee for the message.
     *      - lzTokenFee: The LZ token fee for the message.
     */
    function _quote(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        bool _payInLzToken
    ) internal view virtual returns (MessagingFee memory fee) {
        return
            endpoint.quote(
                MessagingParams(
                    _dstEid,
                    _getPeerOrRevert(_dstEid),
                    _message,
                    _options,
                    _payInLzToken
                ),
                address(this)
            );
    }

    /**
     * @dev Internal function to interact with the LayerZero EndpointV2.send() for sending a message.
     * @param _dstEid The destination endpoint ID.
     * @param _message The message payload.
     * @param _options Additional options for the message.
     * @param _fee The calculated LayerZero fee for the message.
     *      - nativeFee: The native fee.
     *      - lzTokenFee: The lzToken fee.
     * @param _refundAddress The address to receive any excess fee values sent to the endpoint.
     * @return receipt The receipt for the sent message.
     *      - guid: The unique identifier for the sent message.
     *      - nonce: The nonce of the sent message.
     *      - fee: The LayerZero fee incurred for the message.
     */
    function _lzSend(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        MessagingFee memory _fee,
        address _refundAddress
    ) internal virtual returns (MessagingReceipt memory receipt) {
        // @dev Push corresponding fees to the endpoint, any excess is sent back to the _refundAddress from the endpoint.
        uint256 messageValue = _payNative(_fee.nativeFee);
        if (_fee.lzTokenFee > 0) _payLzToken(_fee.lzTokenFee);

        return
            // solhint-disable-next-line check-send-result
            endpoint.send{value: messageValue}(
                MessagingParams(
                    _dstEid,
                    _getPeerOrRevert(_dstEid),
                    _message,
                    _options,
                    _fee.lzTokenFee > 0
                ),
                _refundAddress
            );
    }

    /**
     * @dev Internal function to pay the native fee associated with the message.
     * @param _nativeFee The native fee to be paid.
     * @return nativeFee The amount of native currency paid.
     *
     * @dev If the OApp needs to initiate MULTIPLE LayerZero messages in a single transaction,
     * this will need to be overridden because msg.value would contain multiple lzFees.
     * @dev Should be overridden in the event the LayerZero endpoint requires a different native currency.
     * @dev Some EVMs use an ERC20 as a method for paying transactions/gasFees.
     * @dev The endpoint is EITHER/OR, ie. it will NOT support both types of native payment at a time.
     */
    function _payNative(uint256 _nativeFee) internal virtual returns (uint256 nativeFee) {
        if (msg.value != _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }

    /**
     * @dev Internal function to pay the LZ token fee associated with the message.
     * @param _lzTokenFee The LZ token fee to be paid.
     *
     * @dev If the caller is trying to pay in the specified lzToken, then the lzTokenFee is passed to the endpoint.
     * @dev Any excess sent, is passed back to the specified _refundAddress in the _lzSend().
     */
    function _payLzToken(uint256 _lzTokenFee) internal virtual {
        // @dev Cannot cache the token because it is not immutable in the endpoint.
        address lzToken = endpoint.lzToken();
        if (lzToken == address(0)) revert LzTokenUnavailable();

        // Pay LZ token fee by sending tokens to the endpoint.
        IERC20(lzToken).safeTransferFrom(msg.sender, address(endpoint), _lzTokenFee);
    }
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

// @dev Import the 'MessagingFee' and 'MessagingReceipt' so it's exposed to OApp implementers
// solhint-disable-next-line no-unused-import

// @dev Import the 'Origin' so it's exposed to OApp implementers
// solhint-disable-next-line no-unused-import

/**
 * @title OApp
 * @dev Abstract contract serving as the base for OApp implementation, combining OAppSender and OAppReceiver functionality.
 */
abstract contract OApp is OAppSender, OAppReceiver {
    /**
     * @dev Constructor to initialize the OApp with the provided endpoint and owner.
     * @param _endpoint The address of the LOCAL LayerZero endpoint.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    constructor(address _endpoint, address _delegate) OAppCore(_endpoint, _delegate) {}

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol implementation.
     * @return receiverVersion The version of the OAppReceiver.sol implementation.
     */
    function oAppVersion()
        public
        pure
        virtual
        override(OAppSender, OAppReceiver)
        returns (uint64 senderVersion, uint64 receiverVersion)
    {
        return (SENDER_VERSION, RECEIVER_VERSION);
    }
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @dev Struct representing token parameters for the OFT send() operation.
 */
struct SendParam {
    uint32 dstEid; // Destination endpoint ID.
    bytes32 to; // Recipient address.
    uint256 amountLD; // Amount to send in local decimals.
    uint256 minAmountLD; // Minimum amount to send in local decimals.
    bytes extraOptions; // Additional options supplied by the caller to be used in the LayerZero message.
    bytes composeMsg; // The composed message for the send() operation.
    bytes oftCmd; // The OFT command to be executed, unused in default OFT implementations.
}

/**
 * @dev Struct representing OFT limit information.
 * @dev These amounts can change dynamically and are up the the specific oft implementation.
 */
struct OFTLimit {
    uint256 minAmountLD; // Minimum amount in local decimals that can be sent to the recipient.
    uint256 maxAmountLD; // Maximum amount in local decimals that can be sent to the recipient.
}

/**
 * @dev Struct representing OFT receipt information.
 */
struct OFTReceipt {
    uint256 amountSentLD; // Amount of tokens ACTUALLY debited from the sender in local decimals.
    // @dev In non-default implementations, the amountReceivedLD COULD differ from this value.
    uint256 amountReceivedLD; // Amount of tokens to be received on the remote side.
}

/**
 * @dev Struct representing OFT fee details.
 * @dev Future proof mechanism to provide a standardized way to communicate fees to things like a UI.
 */
struct OFTFeeDetail {
    int256 feeAmountLD; // Amount of the fee in local decimals.
    string description; // Description of the fee.
}

/**
 * @title IOFT
 * @dev Interface for the OftChain (OFT) token.
 * @dev Does not inherit ERC20 to accommodate usage by OFTAdapter as well.
 * @dev This specific interface ID is '0x02e49c2c'.
 */
interface IOFT {
    // Custom error messages
    error InvalidLocalDecimals();
    error SlippageExceeded(uint256 amountLD, uint256 minAmountLD);

    // Events
    event OFTSent(
        bytes32 indexed guid, // GUID of the OFT message.
        uint32 dstEid, // Destination Endpoint ID.
        address indexed fromAddress, // Address of the sender on the src chain.
        uint256 amountSentLD, // Amount of tokens sent in local decimals.
        uint256 amountReceivedLD // Amount of tokens received in local decimals.
    );
    event OFTReceived(
        bytes32 indexed guid, // GUID of the OFT message.
        uint32 srcEid, // Source Endpoint ID.
        address indexed toAddress, // Address of the recipient on the dst chain.
        uint256 amountReceivedLD // Amount of tokens received in local decimals.
    );

    /**
     * @notice Retrieves interfaceID and the version of the OFT.
     * @return interfaceId The interface ID.
     * @return version The version.
     *
     * @dev interfaceId: This specific interface ID is '0x02e49c2c'.
     * @dev version: Indicates a cross-chain compatible msg encoding with other OFTs.
     * @dev If a new feature is added to the OFT cross-chain msg encoding, the version will be incremented.
     * ie. localOFT version(x,1) CAN send messages to remoteOFT version(x,1)
     */
    function oftVersion() external view returns (bytes4 interfaceId, uint64 version);

    /**
     * @notice Retrieves the address of the token associated with the OFT.
     * @return token The address of the ERC20 token implementation.
     */
    function token() external view returns (address);

    /**
     * @notice Indicates whether the OFT contract requires approval of the 'token()' to send.
     * @return requiresApproval Needs approval of the underlying token implementation.
     *
     * @dev Allows things like wallet implementers to determine integration requirements,
     * without understanding the underlying token implementation.
     */
    function approvalRequired() external view returns (bool);

    /**
     * @notice Retrieves the shared decimals of the OFT.
     * @return sharedDecimals The shared decimals of the OFT.
     */
    function sharedDecimals() external view returns (uint8);

    /**
     * @notice Provides a quote for OFT-related operations.
     * @param _sendParam The parameters for the send operation.
     * @return limit The OFT limit information.
     * @return oftFeeDetails The details of OFT fees.
     * @return receipt The OFT receipt information.
     */
    function quoteOFT(
        SendParam calldata _sendParam
    )
        external
        view
        returns (OFTLimit memory, OFTFeeDetail[] memory oftFeeDetails, OFTReceipt memory);

    /**
     * @notice Provides a quote for the send() operation.
     * @param _sendParam The parameters for the send() operation.
     * @param _payInLzToken Flag indicating whether the caller is paying in the LZ token.
     * @return fee The calculated LayerZero messaging fee from the send() operation.
     *
     * @dev MessagingFee: LayerZero msg fee
     *  - nativeFee: The native fee.
     *  - lzTokenFee: The lzToken fee.
     */
    function quoteSend(
        SendParam calldata _sendParam,
        bool _payInLzToken
    ) external view returns (MessagingFee memory);

    /**
     * @notice Executes the send() operation.
     * @param _sendParam The parameters for the send operation.
     * @param _fee The fee information supplied by the caller.
     *      - nativeFee: The native fee.
     *      - lzTokenFee: The lzToken fee.
     * @param _refundAddress The address to receive any excess funds from fees etc. on the src.
     * @return receipt The LayerZero messaging receipt from the send() operation.
     * @return oftReceipt The OFT receipt information.
     *
     * @dev MessagingReceipt: LayerZero msg receipt
     *  - guid: The unique identifier for the sent message.
     *  - nonce: The nonce of the sent message.
     *  - fee: The LayerZero fee incurred for the message.
     */
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory, OFTReceipt memory);
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oapp/interfaces/IOAppMsgInspector.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title IOAppMsgInspector
 * @dev Interface for the OApp Message Inspector, allowing examination of message and options contents.
 */
interface IOAppMsgInspector {
    // Custom error message for inspection failure
    error InspectionFailed(bytes message, bytes options);

    /**
     * @notice Allows the inspector to examine LayerZero message contents and optionally throw a revert if invalid.
     * @param _message The message payload to be inspected.
     * @param _options Additional options or parameters for inspection.
     * @return valid A boolean indicating whether the inspection passed (true) or failed (false).
     *
     * @dev Optionally done as a revert, OR use the boolean provided to handle the failure.
     */
    function inspect(
        bytes calldata _message,
        bytes calldata _options
    ) external view returns (bool valid);
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

library OFTComposeMsgCodec {
    // Offset constants for decoding composed messages
    uint8 private constant NONCE_OFFSET = 8;
    uint8 private constant SRC_EID_OFFSET = 12;
    uint8 private constant AMOUNT_LD_OFFSET = 44;
    uint8 private constant COMPOSE_FROM_OFFSET = 76;

    /**
     * @dev Encodes a OFT composed message.
     * @param _nonce The nonce value.
     * @param _srcEid The source endpoint ID.
     * @param _amountLD The amount in local decimals.
     * @param _composeMsg The composed message.
     * @return _msg The encoded Composed message.
     */
    function encode(
        uint64 _nonce,
        uint32 _srcEid,
        uint256 _amountLD,
        bytes memory _composeMsg // 0x[composeFrom][composeMsg]
    ) internal pure returns (bytes memory _msg) {
        _msg = abi.encodePacked(_nonce, _srcEid, _amountLD, _composeMsg);
    }

    /**
     * @dev Retrieves the nonce from the composed message.
     * @param _msg The message.
     * @return The nonce value.
     */
    function nonce(bytes calldata _msg) internal pure returns (uint64) {
        return uint64(bytes8(_msg[:NONCE_OFFSET]));
    }

    /**
     * @dev Retrieves the source endpoint ID from the composed message.
     * @param _msg The message.
     * @return The source endpoint ID.
     */
    function srcEid(bytes calldata _msg) internal pure returns (uint32) {
        return uint32(bytes4(_msg[NONCE_OFFSET:SRC_EID_OFFSET]));
    }

    /**
     * @dev Retrieves the amount in local decimals from the composed message.
     * @param _msg The message.
     * @return The amount in local decimals.
     */
    function amountLD(bytes calldata _msg) internal pure returns (uint256) {
        return uint256(bytes32(_msg[SRC_EID_OFFSET:AMOUNT_LD_OFFSET]));
    }

    /**
     * @dev Retrieves the composeFrom value from the composed message.
     * @param _msg The message.
     * @return The composeFrom value.
     */
    function composeFrom(bytes calldata _msg) internal pure returns (bytes32) {
        return bytes32(_msg[AMOUNT_LD_OFFSET:COMPOSE_FROM_OFFSET]);
    }

    /**
     * @dev Retrieves the composed message.
     * @param _msg The message.
     * @return The composed message.
     */
    function composeMsg(bytes calldata _msg) internal pure returns (bytes memory) {
        return _msg[COMPOSE_FROM_OFFSET:];
    }

    /**
     * @dev Converts an address to bytes32.
     * @param _addr The address to convert.
     * @return The bytes32 representation of the address.
     */
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    /**
     * @dev Converts bytes32 to an address.
     * @param _b The bytes32 value to convert.
     * @return The address representation of bytes32.
     */
    function bytes32ToAddress(bytes32 _b) internal pure returns (address) {
        return address(uint160(uint256(_b)));
    }
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

library OFTMsgCodec {
    // Offset constants for encoding and decoding OFT messages
    uint8 private constant SEND_TO_OFFSET = 32;
    uint8 private constant SEND_AMOUNT_SD_OFFSET = 40;

    /**
     * @dev Encodes an OFT LayerZero message.
     * @param _sendTo The recipient address.
     * @param _amountShared The amount in shared decimals.
     * @param _composeMsg The composed message.
     * @return _msg The encoded message.
     * @return hasCompose A boolean indicating whether the message has a composed payload.
     */
    function encode(
        bytes32 _sendTo,
        uint64 _amountShared,
        bytes memory _composeMsg
    ) internal view returns (bytes memory _msg, bool hasCompose) {
        hasCompose = _composeMsg.length > 0;
        // @dev Remote chains will want to know the composed function caller ie. msg.sender on the src.
        _msg = hasCompose
            ? abi.encodePacked(_sendTo, _amountShared, addressToBytes32(msg.sender), _composeMsg)
            : abi.encodePacked(_sendTo, _amountShared);
    }

    /**
     * @dev Checks if the OFT message is composed.
     * @param _msg The OFT message.
     * @return A boolean indicating whether the message is composed.
     */
    function isComposed(bytes calldata _msg) internal pure returns (bool) {
        return _msg.length > SEND_AMOUNT_SD_OFFSET;
    }

    /**
     * @dev Retrieves the recipient address from the OFT message.
     * @param _msg The OFT message.
     * @return The recipient address.
     */
    function sendTo(bytes calldata _msg) internal pure returns (bytes32) {
        return bytes32(_msg[:SEND_TO_OFFSET]);
    }

    /**
     * @dev Retrieves the amount in shared decimals from the OFT message.
     * @param _msg The OFT message.
     * @return The amount in shared decimals.
     */
    function amountSD(bytes calldata _msg) internal pure returns (uint64) {
        return uint64(bytes8(_msg[SEND_TO_OFFSET:SEND_AMOUNT_SD_OFFSET]));
    }

    /**
     * @dev Retrieves the composed message from the OFT message.
     * @param _msg The OFT message.
     * @return The composed message.
     */
    function composeMsg(bytes calldata _msg) internal pure returns (bytes memory) {
        return _msg[SEND_AMOUNT_SD_OFFSET:];
    }

    /**
     * @dev Converts an address to bytes32.
     * @param _addr The address to convert.
     * @return The bytes32 representation of the address.
     */
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    /**
     * @dev Converts bytes32 to an address.
     * @param _b The bytes32 value to convert.
     * @return The address representation of bytes32.
     */
    function bytes32ToAddress(bytes32 _b) internal pure returns (address) {
        return address(uint160(uint256(_b)));
    }
}

// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File @layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLib.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity >=0.8.0;

enum MessageLibType {
    Send,
    Receive,
    SendAndReceive
}

interface IMessageLib is IERC165 {
    function setConfig(address _oapp, SetConfigParam[] calldata _config) external;

    function getConfig(
        uint32 _eid,
        address _oapp,
        uint32 _configType
    ) external view returns (bytes memory config);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    // message libs of same major version are compatible
    function version() external view returns (uint64 major, uint8 minor, uint8 endpointVersion);

    function messageLibType() external view returns (MessageLibType);
}

// File @layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ISendLib.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity >=0.8.0;

struct Packet {
    uint64 nonce;
    uint32 srcEid;
    address sender;
    uint32 dstEid;
    bytes32 receiver;
    bytes32 guid;
    bytes message;
}

interface ISendLib is IMessageLib {
    function send(
        Packet calldata _packet,
        bytes calldata _options,
        bool _payInLzToken
    ) external returns (MessagingFee memory, bytes memory encodedPacket);

    function quote(
        Packet calldata _packet,
        bytes calldata _options,
        bool _payInLzToken
    ) external view returns (MessagingFee memory);

    function setTreasury(address _treasury) external;

    function withdrawFee(address _to, uint256 _amount) external;

    function withdrawLzTokenFee(address _lzToken, address _to, uint256 _amount) external;
}

// File @layerzerolabs/lz-evm-protocol-v2/contracts/libs/AddressCast.sol@v2.3.40

// Original license: SPDX_License_Identifier: LZBL-1.2

pragma solidity ^0.8.20;

library AddressCast {
    error AddressCast_InvalidSizeForAddress();
    error AddressCast_InvalidAddress();

    function toBytes32(bytes calldata _addressBytes) internal pure returns (bytes32 result) {
        if (_addressBytes.length > 32) revert AddressCast_InvalidAddress();
        result = bytes32(_addressBytes);
        unchecked {
            uint256 offset = 32 - _addressBytes.length;
            result = result >> (offset * 8);
        }
    }

    function toBytes32(address _address) internal pure returns (bytes32 result) {
        result = bytes32(uint256(uint160(_address)));
    }

    function toBytes(
        bytes32 _addressBytes32,
        uint256 _size
    ) internal pure returns (bytes memory result) {
        if (_size == 0 || _size > 32) revert AddressCast_InvalidSizeForAddress();
        result = new bytes(_size);
        unchecked {
            uint256 offset = 256 - _size * 8;
            assembly {
                mstore(add(result, 32), shl(offset, _addressBytes32))
            }
        }
    }

    function toAddress(bytes32 _addressBytes32) internal pure returns (address result) {
        result = address(uint160(uint256(_addressBytes32)));
    }

    function toAddress(bytes calldata _addressBytes) internal pure returns (address result) {
        if (_addressBytes.length != 20) revert AddressCast_InvalidAddress();
        result = address(bytes20(_addressBytes));
    }
}

// File @layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/PacketV1Codec.sol@v2.3.40

// Original license: SPDX_License_Identifier: LZBL-1.2

pragma solidity ^0.8.20;

library PacketV1Codec {
    using AddressCast for address;
    using AddressCast for bytes32;

    uint8 internal constant PACKET_VERSION = 1;

    // header (version + nonce + path)
    // version
    uint256 private constant PACKET_VERSION_OFFSET = 0;
    //    nonce
    uint256 private constant NONCE_OFFSET = 1;
    //    path
    uint256 private constant SRC_EID_OFFSET = 9;
    uint256 private constant SENDER_OFFSET = 13;
    uint256 private constant DST_EID_OFFSET = 45;
    uint256 private constant RECEIVER_OFFSET = 49;
    // payload (guid + message)
    uint256 private constant GUID_OFFSET = 81; // keccak256(nonce + path)
    uint256 private constant MESSAGE_OFFSET = 113;

    function encode(Packet memory _packet) internal pure returns (bytes memory encodedPacket) {
        encodedPacket = abi.encodePacked(
            PACKET_VERSION,
            _packet.nonce,
            _packet.srcEid,
            _packet.sender.toBytes32(),
            _packet.dstEid,
            _packet.receiver,
            _packet.guid,
            _packet.message
        );
    }

    function encodePacketHeader(Packet memory _packet) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                PACKET_VERSION,
                _packet.nonce,
                _packet.srcEid,
                _packet.sender.toBytes32(),
                _packet.dstEid,
                _packet.receiver
            );
    }

    function encodePayload(Packet memory _packet) internal pure returns (bytes memory) {
        return abi.encodePacked(_packet.guid, _packet.message);
    }

    function header(bytes calldata _packet) internal pure returns (bytes calldata) {
        return _packet[0:GUID_OFFSET];
    }

    function version(bytes calldata _packet) internal pure returns (uint8) {
        return uint8(bytes1(_packet[PACKET_VERSION_OFFSET:NONCE_OFFSET]));
    }

    function nonce(bytes calldata _packet) internal pure returns (uint64) {
        return uint64(bytes8(_packet[NONCE_OFFSET:SRC_EID_OFFSET]));
    }

    function srcEid(bytes calldata _packet) internal pure returns (uint32) {
        return uint32(bytes4(_packet[SRC_EID_OFFSET:SENDER_OFFSET]));
    }

    function sender(bytes calldata _packet) internal pure returns (bytes32) {
        return bytes32(_packet[SENDER_OFFSET:DST_EID_OFFSET]);
    }

    function senderAddressB20(bytes calldata _packet) internal pure returns (address) {
        return sender(_packet).toAddress();
    }

    function dstEid(bytes calldata _packet) internal pure returns (uint32) {
        return uint32(bytes4(_packet[DST_EID_OFFSET:RECEIVER_OFFSET]));
    }

    function receiver(bytes calldata _packet) internal pure returns (bytes32) {
        return bytes32(_packet[RECEIVER_OFFSET:GUID_OFFSET]);
    }

    function receiverB20(bytes calldata _packet) internal pure returns (address) {
        return receiver(_packet).toAddress();
    }

    function guid(bytes calldata _packet) internal pure returns (bytes32) {
        return bytes32(_packet[GUID_OFFSET:MESSAGE_OFFSET]);
    }

    function message(bytes calldata _packet) internal pure returns (bytes calldata) {
        return bytes(_packet[MESSAGE_OFFSET:]);
    }

    function payload(bytes calldata _packet) internal pure returns (bytes calldata) {
        return bytes(_packet[GUID_OFFSET:]);
    }

    function payloadHash(bytes calldata _packet) internal pure returns (bytes32) {
        return keccak256(payload(_packet));
    }
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/precrime/libs/Packet.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title InboundPacket
 * @dev Structure representing an inbound packet received by the contract.
 */
struct InboundPacket {
    Origin origin; // Origin information of the packet.
    uint32 dstEid; // Destination endpointId of the packet.
    address receiver; // Receiver address for the packet.
    bytes32 guid; // Unique identifier of the packet.
    uint256 value; // msg.value of the packet.
    address executor; // Executor address for the packet.
    bytes message; // Message payload of the packet.
    bytes extraData; // Additional arbitrary data for the packet.
}

/**
 * @title PacketDecoder
 * @dev Library for decoding LayerZero packets.
 */
library PacketDecoder {
    using PacketV1Codec for bytes;

    /**
     * @dev Decode an inbound packet from the given packet data.
     * @param _packet The packet data to decode.
     * @return packet An InboundPacket struct representing the decoded packet.
     */
    function decode(bytes calldata _packet) internal pure returns (InboundPacket memory packet) {
        packet.origin = Origin(_packet.srcEid(), _packet.sender(), _packet.nonce());
        packet.dstEid = _packet.dstEid();
        packet.receiver = _packet.receiverB20();
        packet.guid = _packet.guid();
        packet.message = _packet.message();
    }

    /**
     * @dev Decode multiple inbound packets from the given packet data and associated message values.
     * @param _packets An array of packet data to decode.
     * @param _packetMsgValues An array of associated message values for each packet.
     * @return packets An array of InboundPacket structs representing the decoded packets.
     */
    function decode(
        bytes[] calldata _packets,
        uint256[] memory _packetMsgValues
    ) internal pure returns (InboundPacket[] memory packets) {
        packets = new InboundPacket[](_packets.length);
        for (uint256 i = 0; i < _packets.length; i++) {
            bytes calldata packet = _packets[i];
            packets[i] = PacketDecoder.decode(packet);
            // @dev Allows the verifier to specify the msg.value that gets passed in lzReceive.
            packets[i].value = _packetMsgValues[i];
        }
    }
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/precrime/interfaces/IOAppPreCrimeSimulator.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

// @dev Import the Origin so it's exposed to OAppPreCrimeSimulator implementers.
// solhint-disable-next-line no-unused-import

/**
 * @title IOAppPreCrimeSimulator Interface
 * @dev Interface for the preCrime simulation functionality in an OApp.
 */
interface IOAppPreCrimeSimulator {
    // @dev simulation result used in PreCrime implementation
    error SimulationResult(bytes result);
    error OnlySelf();

    /**
     * @dev Emitted when the preCrime contract address is set.
     * @param preCrimeAddress The address of the preCrime contract.
     */
    event PreCrimeSet(address preCrimeAddress);

    /**
     * @dev Retrieves the address of the preCrime contract implementation.
     * @return The address of the preCrime contract.
     */
    function preCrime() external view returns (address);

    /**
     * @dev Retrieves the address of the OApp contract.
     * @return The address of the OApp contract.
     */
    function oApp() external view returns (address);

    /**
     * @dev Sets the preCrime contract address.
     * @param _preCrime The address of the preCrime contract.
     */
    function setPreCrime(address _preCrime) external;

    /**
     * @dev Mocks receiving a packet, then reverts with a series of data to infer the state/result.
     * @param _packets An array of LayerZero InboundPacket objects representing received packets.
     */
    function lzReceiveAndRevert(InboundPacket[] calldata _packets) external payable;

    /**
     * @dev checks if the specified peer is considered 'trusted' by the OApp.
     * @param _eid The endpoint Id to check.
     * @param _peer The peer to check.
     * @return Whether the peer passed is considered 'trusted' by the OApp.
     */
    function isPeer(uint32 _eid, bytes32 _peer) external view returns (bool);
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/precrime/interfaces/IPreCrime.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;
struct PreCrimePeer {
    uint32 eid;
    bytes32 preCrime;
    bytes32 oApp;
}

// TODO not done yet
interface IPreCrime {
    error OnlyOffChain();

    // for simulate()
    error PacketOversize(uint256 max, uint256 actual);
    error PacketUnsorted();
    error SimulationFailed(bytes reason);

    // for preCrime()
    error SimulationResultNotFound(uint32 eid);
    error InvalidSimulationResult(uint32 eid, bytes reason);
    error CrimeFound(bytes crime);

    function getConfig(
        bytes[] calldata _packets,
        uint256[] calldata _packetMsgValues
    ) external returns (bytes memory);

    function simulate(
        bytes[] calldata _packets,
        uint256[] calldata _packetMsgValues
    ) external payable returns (bytes memory);

    function buildSimulationResult() external view returns (bytes memory);

    function preCrime(
        bytes[] calldata _packets,
        uint256[] calldata _packetMsgValues,
        bytes[] calldata _simulations
    ) external;

    function version() external view returns (uint64 major, uint8 minor);
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/precrime/OAppPreCrimeSimulator.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title OAppPreCrimeSimulator
 * @dev Abstract contract serving as the base for preCrime simulation functionality in an OApp.
 */
abstract contract OAppPreCrimeSimulator is IOAppPreCrimeSimulator, Ownable {
    // The address of the preCrime implementation.
    address public preCrime;

    /**
     * @dev Retrieves the address of the OApp contract.
     * @return The address of the OApp contract.
     *
     * @dev The simulator contract is the base contract for the OApp by default.
     * @dev If the simulator is a separate contract, override this function.
     */
    function oApp() external view virtual returns (address) {
        return address(this);
    }

    /**
     * @dev Sets the preCrime contract address.
     * @param _preCrime The address of the preCrime contract.
     */
    function setPreCrime(address _preCrime) public virtual onlyOwner {
        preCrime = _preCrime;
        emit PreCrimeSet(_preCrime);
    }

    /**
     * @dev Interface for pre-crime simulations. Always reverts at the end with the simulation results.
     * @param _packets An array of InboundPacket objects representing received packets to be delivered.
     *
     * @dev WARNING: MUST revert at the end with the simulation results.
     * @dev Gives the preCrime implementation the ability to mock sending packets to the lzReceive function,
     * WITHOUT actually executing them.
     */
    function lzReceiveAndRevert(InboundPacket[] calldata _packets) public payable virtual {
        for (uint256 i = 0; i < _packets.length; i++) {
            InboundPacket calldata packet = _packets[i];

            // Ignore packets that are not from trusted peers.
            if (!isPeer(packet.origin.srcEid, packet.origin.sender)) continue;

            // @dev Because a verifier is calling this function, it doesnt have access to executor params:
            //  - address _executor
            //  - bytes calldata _extraData
            // preCrime will NOT work for OApps that rely on these two parameters inside of their _lzReceive().
            // They are instead stubbed to default values, address(0) and bytes("")
            // @dev Calling this.lzReceiveSimulate removes ability for assembly return 0 callstack exit,
            // which would cause the revert to be ignored.
            this.lzReceiveSimulate{value: packet.value}(
                packet.origin,
                packet.guid,
                packet.message,
                packet.executor,
                packet.extraData
            );
        }

        // @dev Revert with the simulation results. msg.sender must implement IPreCrime.buildSimulationResult().
        revert SimulationResult(IPreCrime(msg.sender).buildSimulationResult());
    }

    /**
     * @dev Is effectively an internal function because msg.sender must be address(this).
     * Allows resetting the call stack for 'internal' calls.
     * @param _origin The origin information containing the source endpoint and sender address.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address on the src chain.
     *  - nonce: The nonce of the message.
     * @param _guid The unique identifier of the packet.
     * @param _message The message payload of the packet.
     * @param _executor The executor address for the packet.
     * @param _extraData Additional data for the packet.
     */
    function lzReceiveSimulate(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable virtual {
        // @dev Ensure ONLY can be called 'internally'.
        if (msg.sender != address(this)) revert OnlySelf();
        _lzReceiveSimulate(_origin, _guid, _message, _executor, _extraData);
    }

    /**
     * @dev Internal function to handle the OAppPreCrimeSimulator simulated receive.
     * @param _origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @param _guid The GUID of the LayerZero message.
     * @param _message The LayerZero message.
     * @param _executor The address of the off-chain executor.
     * @param _extraData Arbitrary data passed by the msg executor.
     *
     * @dev Enables the preCrime simulator to mock sending lzReceive() messages,
     * routes the msg down from the OAppPreCrimeSimulator, and back up to the OAppReceiver.
     */
    function _lzReceiveSimulate(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual;

    /**
     * @dev checks if the specified peer is considered 'trusted' by the OApp.
     * @param _eid The endpoint Id to check.
     * @param _peer The peer to check.
     * @return Whether the peer passed is considered 'trusted' by the OApp.
     */
    function isPeer(uint32 _eid, bytes32 _peer) public view virtual returns (bool);
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title OFTCore
 * @dev Abstract contract for the OftChain (OFT) token.
 */
abstract contract OFTCore is IOFT, OApp, OAppPreCrimeSimulator, OAppOptionsType3 {
    using OFTMsgCodec for bytes;
    using OFTMsgCodec for bytes32;

    // @notice Provides a conversion rate when swapping between denominations of SD and LD
    //      - shareDecimals == SD == shared Decimals
    //      - localDecimals == LD == local decimals
    // @dev Considers that tokens have different decimal amounts on various chains.
    // @dev eg.
    //  For a token
    //      - locally with 4 decimals --> 1.2345 => uint(12345)
    //      - remotely with 2 decimals --> 1.23 => uint(123)
    //      - The conversion rate would be 10 ** (4 - 2) = 100
    //  @dev If you want to send 1.2345 -> (uint 12345), you CANNOT represent that value on the remote,
    //  you can only display 1.23 -> uint(123).
    //  @dev To preserve the dust that would otherwise be lost on that conversion,
    //  we need to unify a denomination that can be represented on ALL chains inside of the OFT mesh
    uint256 public immutable decimalConversionRate;

    // @notice Msg types that are used to identify the various OFT operations.
    // @dev This can be extended in child contracts for non-default oft operations
    // @dev These values are used in things like combineOptions() in OAppOptionsType3.sol.
    uint16 public constant SEND = 1;
    uint16 public constant SEND_AND_CALL = 2;

    // Address of an optional contract to inspect both 'message' and 'options'
    address public msgInspector;
    event MsgInspectorSet(address inspector);

    /**
     * @dev Constructor.
     * @param _localDecimals The decimals of the token on the local chain (this chain).
     * @param _endpoint The address of the LayerZero endpoint.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    constructor(
        uint8 _localDecimals,
        address _endpoint,
        address _delegate
    ) OApp(_endpoint, _delegate) {
        if (_localDecimals < sharedDecimals()) revert InvalidLocalDecimals();
        decimalConversionRate = 10 ** (_localDecimals - sharedDecimals());
    }

    /**
     * @notice Retrieves interfaceID and the version of the OFT.
     * @return interfaceId The interface ID.
     * @return version The version.
     *
     * @dev interfaceId: This specific interface ID is '0x02e49c2c'.
     * @dev version: Indicates a cross-chain compatible msg encoding with other OFTs.
     * @dev If a new feature is added to the OFT cross-chain msg encoding, the version will be incremented.
     * ie. localOFT version(x,1) CAN send messages to remoteOFT version(x,1)
     */
    function oftVersion() external pure virtual returns (bytes4 interfaceId, uint64 version) {
        return (type(IOFT).interfaceId, 1);
    }

    /**
     * @dev Retrieves the shared decimals of the OFT.
     * @return The shared decimals of the OFT.
     *
     * @dev Sets an implicit cap on the amount of tokens, over uint64.max() will need some sort of outbound cap / totalSupply cap
     * Lowest common decimal denominator between chains.
     * Defaults to 6 decimal places to provide up to 18,446,744,073,709.551615 units (max uint64).
     * For tokens exceeding this totalSupply(), they will need to override the sharedDecimals function with something smaller.
     * ie. 4 sharedDecimals would be 1,844,674,407,370,955.1615
     */
    function sharedDecimals() public view virtual returns (uint8) {
        return 6;
    }

    /**
     * @dev Sets the message inspector address for the OFT.
     * @param _msgInspector The address of the message inspector.
     *
     * @dev This is an optional contract that can be used to inspect both 'message' and 'options'.
     * @dev Set it to address(0) to disable it, or set it to a contract address to enable it.
     */
    function setMsgInspector(address _msgInspector) public virtual onlyOwner {
        msgInspector = _msgInspector;
        emit MsgInspectorSet(_msgInspector);
    }

    /**
     * @notice Provides a quote for OFT-related operations.
     * @param _sendParam The parameters for the send operation.
     * @return oftLimit The OFT limit information.
     * @return oftFeeDetails The details of OFT fees.
     * @return oftReceipt The OFT receipt information.
     */
    function quoteOFT(
        SendParam calldata _sendParam
    )
        external
        view
        virtual
        returns (
            OFTLimit memory oftLimit,
            OFTFeeDetail[] memory oftFeeDetails,
            OFTReceipt memory oftReceipt
        )
    {
        uint256 minAmountLD = 0; // Unused in the default implementation.
        uint256 maxAmountLD = type(uint64).max; // Unused in the default implementation.
        oftLimit = OFTLimit(minAmountLD, maxAmountLD);

        // Unused in the default implementation; reserved for future complex fee details.
        oftFeeDetails = new OFTFeeDetail[](0);

        // @dev This is the same as the send() operation, but without the actual send.
        // - amountSentLD is the amount in local decimals that would be sent from the sender.
        // - amountReceivedLD is the amount in local decimals that will be credited to the recipient on the remote OFT instance.
        // @dev The amountSentLD MIGHT not equal the amount the user actually receives. HOWEVER, the default does.
        (uint256 amountSentLD, uint256 amountReceivedLD) = _debitView(
            _sendParam.amountLD,
            _sendParam.minAmountLD,
            _sendParam.dstEid
        );
        oftReceipt = OFTReceipt(amountSentLD, amountReceivedLD);
    }

    /**
     * @notice Provides a quote for the send() operation.
     * @param _sendParam The parameters for the send() operation.
     * @param _payInLzToken Flag indicating whether the caller is paying in the LZ token.
     * @return msgFee The calculated LayerZero messaging fee from the send() operation.
     *
     * @dev MessagingFee: LayerZero msg fee
     *  - nativeFee: The native fee.
     *  - lzTokenFee: The lzToken fee.
     */
    function quoteSend(
        SendParam calldata _sendParam,
        bool _payInLzToken
    ) external view virtual returns (MessagingFee memory msgFee) {
        // @dev mock the amount to receive, this is the same operation used in the send().
        // The quote is as similar as possible to the actual send() operation.
        (, uint256 amountReceivedLD) = _debitView(
            _sendParam.amountLD,
            _sendParam.minAmountLD,
            _sendParam.dstEid
        );

        // @dev Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) = _buildMsgAndOptions(
            _sendParam,
            amountReceivedLD
        );

        // @dev Calculates the LayerZero fee for the send() operation.
        return _quote(_sendParam.dstEid, message, options, _payInLzToken);
    }

    /**
     * @dev Executes the send operation.
     * @param _sendParam The parameters for the send operation.
     * @param _fee The calculated fee for the send() operation.
     *      - nativeFee: The native fee.
     *      - lzTokenFee: The lzToken fee.
     * @param _refundAddress The address to receive any excess funds.
     * @return msgReceipt The receipt for the send operation.
     * @return oftReceipt The OFT receipt information.
     *
     * @dev MessagingReceipt: LayerZero msg receipt
     *  - guid: The unique identifier for the sent message.
     *  - nonce: The nonce of the sent message.
     *  - fee: The LayerZero fee incurred for the message.
     */
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    )
        external
        payable
        virtual
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt)
    {
        // @dev Applies the token transfers regarding this send() operation.
        // - amountSentLD is the amount in local decimals that was ACTUALLY sent/debited from the sender.
        // - amountReceivedLD is the amount in local decimals that will be received/credited to the recipient on the remote OFT instance.
        (uint256 amountSentLD, uint256 amountReceivedLD) = _debit(
            msg.sender,
            _sendParam.amountLD,
            _sendParam.minAmountLD,
            _sendParam.dstEid
        );

        // @dev Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) = _buildMsgAndOptions(
            _sendParam,
            amountReceivedLD
        );

        // @dev Sends the message to the LayerZero endpoint and returns the LayerZero msg receipt.
        msgReceipt = _lzSend(_sendParam.dstEid, message, options, _fee, _refundAddress);
        // @dev Formulate the OFT receipt.
        oftReceipt = OFTReceipt(amountSentLD, amountReceivedLD);

        emit OFTSent(
            msgReceipt.guid,
            _sendParam.dstEid,
            msg.sender,
            amountSentLD,
            amountReceivedLD
        );
    }

    /**
     * @dev Internal function to build the message and options.
     * @param _sendParam The parameters for the send() operation.
     * @param _amountLD The amount in local decimals.
     * @return message The encoded message.
     * @return options The encoded options.
     */
    function _buildMsgAndOptions(
        SendParam calldata _sendParam,
        uint256 _amountLD
    ) internal view virtual returns (bytes memory message, bytes memory options) {
        bool hasCompose;
        // @dev This generated message has the msg.sender encoded into the payload so the remote knows who the caller is.
        (message, hasCompose) = OFTMsgCodec.encode(
            _sendParam.to,
            _toSD(_amountLD),
            // @dev Must be include a non empty bytes if you want to compose, EVEN if you dont need it on the remote.
            // EVEN if you dont require an arbitrary payload to be sent... eg. '0x01'
            _sendParam.composeMsg
        );
        // @dev Change the msg type depending if its composed or not.
        uint16 msgType = hasCompose ? SEND_AND_CALL : SEND;
        // @dev Combine the callers _extraOptions with the enforced options via the OAppOptionsType3.
        options = combineOptions(_sendParam.dstEid, msgType, _sendParam.extraOptions);

        // @dev Optionally inspect the message and options depending if the OApp owner has set a msg inspector.
        // @dev If it fails inspection, needs to revert in the implementation. ie. does not rely on return boolean
        if (msgInspector != address(0)) IOAppMsgInspector(msgInspector).inspect(message, options);
    }

    /**
     * @dev Internal function to handle the receive on the LayerZero endpoint.
     * @param _origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @param _guid The unique identifier for the received LayerZero message.
     * @param _message The encoded message.
     * @dev _executor The address of the executor.
     * @dev _extraData Additional data.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address /*_executor*/, // @dev unused in the default implementation.
        bytes calldata /*_extraData*/ // @dev unused in the default implementation.
    ) internal virtual override {
        // @dev The src sending chain doesnt know the address length on this chain (potentially non-evm)
        // Thus everything is bytes32() encoded in flight.
        address toAddress = _message.sendTo().bytes32ToAddress();
        // @dev Credit the amountLD to the recipient and return the ACTUAL amount the recipient received in local decimals
        uint256 amountReceivedLD = _credit(toAddress, _toLD(_message.amountSD()), _origin.srcEid);

        if (_message.isComposed()) {
            // @dev Proprietary composeMsg format for the OFT.
            bytes memory composeMsg = OFTComposeMsgCodec.encode(
                _origin.nonce,
                _origin.srcEid,
                amountReceivedLD,
                _message.composeMsg()
            );

            // @dev Stores the lzCompose payload that will be executed in a separate tx.
            // Standardizes functionality for executing arbitrary contract invocation on some non-evm chains.
            // @dev The off-chain executor will listen and process the msg based on the src-chain-callers compose options passed.
            // @dev The index is used when a OApp needs to compose multiple msgs on lzReceive.
            // For default OFT implementation there is only 1 compose msg per lzReceive, thus its always 0.
            endpoint.sendCompose(
                toAddress,
                _guid,
                0 /* the index of the composed message*/,
                composeMsg
            );
        }

        emit OFTReceived(_guid, _origin.srcEid, toAddress, amountReceivedLD);
    }

    /**
     * @dev Internal function to handle the OAppPreCrimeSimulator simulated receive.
     * @param _origin The origin information.
     *  - srcEid: The source chain endpoint ID.
     *  - sender: The sender address from the src chain.
     *  - nonce: The nonce of the LayerZero message.
     * @param _guid The unique identifier for the received LayerZero message.
     * @param _message The LayerZero message.
     * @param _executor The address of the off-chain executor.
     * @param _extraData Arbitrary data passed by the msg executor.
     *
     * @dev Enables the preCrime simulator to mock sending lzReceive() messages,
     * routes the msg down from the OAppPreCrimeSimulator, and back up to the OAppReceiver.
     */
    function _lzReceiveSimulate(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual override {
        _lzReceive(_origin, _guid, _message, _executor, _extraData);
    }

    /**
     * @dev Check if the peer is considered 'trusted' by the OApp.
     * @param _eid The endpoint ID to check.
     * @param _peer The peer to check.
     * @return Whether the peer passed is considered 'trusted' by the OApp.
     *
     * @dev Enables OAppPreCrimeSimulator to check whether a potential Inbound Packet is from a trusted source.
     */
    function isPeer(uint32 _eid, bytes32 _peer) public view virtual override returns (bool) {
        return peers[_eid] == _peer;
    }

    /**
     * @dev Internal function to remove dust from the given local decimal amount.
     * @param _amountLD The amount in local decimals.
     * @return amountLD The amount after removing dust.
     *
     * @dev Prevents the loss of dust when moving amounts between chains with different decimals.
     * @dev eg. uint(123) with a conversion rate of 100 becomes uint(100).
     */
    function _removeDust(uint256 _amountLD) internal view virtual returns (uint256 amountLD) {
        return (_amountLD / decimalConversionRate) * decimalConversionRate;
    }

    /**
     * @dev Internal function to convert an amount from shared decimals into local decimals.
     * @param _amountSD The amount in shared decimals.
     * @return amountLD The amount in local decimals.
     */
    function _toLD(uint64 _amountSD) internal view virtual returns (uint256 amountLD) {
        return _amountSD * decimalConversionRate;
    }

    /**
     * @dev Internal function to convert an amount from local decimals into shared decimals.
     * @param _amountLD The amount in local decimals.
     * @return amountSD The amount in shared decimals.
     */
    function _toSD(uint256 _amountLD) internal view virtual returns (uint64 amountSD) {
        return uint64(_amountLD / decimalConversionRate);
    }

    /**
     * @dev Internal function to mock the amount mutation from a OFT debit() operation.
     * @param _amountLD The amount to send in local decimals.
     * @param _minAmountLD The minimum amount to send in local decimals.
     * @dev _dstEid The destination endpoint ID.
     * @return amountSentLD The amount sent, in local decimals.
     * @return amountReceivedLD The amount to be received on the remote chain, in local decimals.
     *
     * @dev This is where things like fees would be calculated and deducted from the amount to be received on the remote.
     */
    function _debitView(
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 /*_dstEid*/
    ) internal view virtual returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        // @dev Remove the dust so nothing is lost on the conversion between chains with different decimals for the token.
        amountSentLD = _removeDust(_amountLD);
        // @dev The amount to send is the same as amount received in the default implementation.
        amountReceivedLD = amountSentLD;

        // @dev Check for slippage.
        if (amountReceivedLD < _minAmountLD) {
            revert SlippageExceeded(amountReceivedLD, _minAmountLD);
        }
    }

    /**
     * @dev Internal function to perform a debit operation.
     * @param _from The address to debit.
     * @param _amountLD The amount to send in local decimals.
     * @param _minAmountLD The minimum amount to send in local decimals.
     * @param _dstEid The destination endpoint ID.
     * @return amountSentLD The amount sent in local decimals.
     * @return amountReceivedLD The amount received in local decimals on the remote.
     *
     * @dev Defined here but are intended to be overriden depending on the OFT implementation.
     * @dev Depending on OFT implementation the _amountLD could differ from the amountReceivedLD.
     */
    function _debit(
        address _from,
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    ) internal virtual returns (uint256 amountSentLD, uint256 amountReceivedLD);

    /**
     * @dev Internal function to perform a credit operation.
     * @param _to The address to credit.
     * @param _amountLD The amount to credit in local decimals.
     * @param _srcEid The source endpoint ID.
     * @return amountReceivedLD The amount ACTUALLY received in local decimals.
     *
     * @dev Defined here but are intended to be overriden depending on the OFT implementation.
     * @dev Depending on OFT implementation the _amountLD could differ from the amountReceivedLD.
     */
    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 _srcEid
    ) internal virtual returns (uint256 amountReceivedLD);
}

// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File @openzeppelin/contracts/token/ERC20/ERC20.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File @layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol@v2.3.40

// Original license: SPDX_License_Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title OFT Contract
 * @dev OFT is an ERC-20 token that extends the functionality of the OFTCore contract.
 */
abstract contract OFT is OFTCore, ERC20 {
    /**
     * @dev Constructor for the OFT contract.
     * @param _name The name of the OFT.
     * @param _symbol The symbol of the OFT.
     * @param _lzEndpoint The LayerZero endpoint address.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) ERC20(_name, _symbol) OFTCore(decimals(), _lzEndpoint, _delegate) {}

    /**
     * @dev Retrieves the address of the underlying ERC20 implementation.
     * @return The address of the OFT token.
     *
     * @dev In the case of OFT, address(this) and erc20 are the same contract.
     */
    function token() public view returns (address) {
        return address(this);
    }

    /**
     * @notice Indicates whether the OFT contract requires approval of the 'token()' to send.
     * @return requiresApproval Needs approval of the underlying token implementation.
     *
     * @dev In the case of OFT where the contract IS the token, approval is NOT required.
     */
    function approvalRequired() external pure virtual returns (bool) {
        return false;
    }

    /**
     * @dev Burns tokens from the sender's specified balance.
     * @param _from The address to debit the tokens from.
     * @param _amountLD The amount of tokens to send in local decimals.
     * @param _minAmountLD The minimum amount to send in local decimals.
     * @param _dstEid The destination chain ID.
     * @return amountSentLD The amount sent in local decimals.
     * @return amountReceivedLD The amount received in local decimals on the remote.
     */
    function _debit(
        address _from,
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    ) internal virtual override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);

        // @dev In NON-default OFT, amountSentLD could be 100, with a 10% fee, the amountReceivedLD amount is 90,
        // therefore amountSentLD CAN differ from amountReceivedLD.

        // @dev Default OFT burns on src.
        _burn(_from, amountSentLD);
    }

    /**
     * @dev Credits tokens to the specified address.
     * @param _to The address to credit the tokens to.
     * @param _amountLD The amount of tokens to credit in local decimals.
     * @dev _srcEid The source chain ID.
     * @return amountReceivedLD The amount of tokens ACTUALLY received in local decimals.
     */
    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 /*_srcEid*/
    ) internal virtual override returns (uint256 amountReceivedLD) {
        if (_to == address(0x0)) _to = address(0xdead); // _mint(...) does not support address(0x0)
        // @dev Default OFT mints on dst.
        _mint(_to, _amountLD);
        // @dev In the case of NON-default OFT, the _amountLD MIGHT not be == amountReceivedLD.
        return _amountLD;
    }
}

// File @openzeppelin/contracts/utils/Counters.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File @openzeppelin/contracts/utils/math/Math.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// File @openzeppelin/contracts/utils/math/SignedMath.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File @openzeppelin/contracts/utils/Strings.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File @openzeppelin/contracts/utils/cryptography/ECDSA.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs &
            bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s)
            );
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    ) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(
        address validator,
        bytes memory data
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// File @openzeppelin/contracts/interfaces/IERC5267.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// File @openzeppelin/contracts/utils/StorageSlot.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// File @openzeppelin/contracts/utils/ShortStrings.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.8;

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL =
        0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(
        string memory value,
        string storage store
    ) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(
        ShortString value,
        string storage store
    ) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(
        ShortString value,
        string storage store
    ) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// File @openzeppelin/contracts/utils/cryptography/EIP712.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this))
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// File @openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol@v4.9.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// File contracts/LamboLlama.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.22;

contract LamboLlama is OFT, ERC20Permit {
    constructor(
        address _delegate,
        uint256 _supply,
        bool _mintSupply,
        address _lzEndpointAddress
    ) OFT("LamboLlama", "LLL", _lzEndpointAddress, _delegate) ERC20Permit("LamboLlama") {
        _transferOwnership(_delegate);
        if (_mintSupply) {
            _mint(_delegate, _supply);
        }
    }
}
