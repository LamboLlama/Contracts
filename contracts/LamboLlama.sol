// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

contract LamboLlama is ERC20Permit, OFT {
    // local ganache 31337, gnosis 100
    uint256 constant INITIAL_CHAIN_ID = 100;

    constructor(
        address _delegate,
        uint256 _supply,
        address _lzEndpointAddress
    ) ERC20Permit("LamboLlama") OFT("LamboLlama", "LLL", _lzEndpointAddress, _delegate) {
        _transferOwnership(_delegate);

        if (block.chainid == INITIAL_CHAIN_ID) {
            _mint(_delegate, _supply);
        }
    }
}
