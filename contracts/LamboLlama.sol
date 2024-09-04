// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

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
