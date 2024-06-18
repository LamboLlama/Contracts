// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract LamboLlama is ERC20Permit, OFT {
    constructor(
        address _addressAirdrop,
        address _addressTeam,
        uint256 _supplyDex,
        uint256 _supplyAirdrop,
        uint256 _supplyTeam,
        address _delegate,
        address _lzEndpointAddress
    ) ERC20Permit("LamboLlama") OFT("LamboLlama", "LLL", _lzEndpointAddress, _delegate) {
        _transferOwnership(_delegate);
        _mint(_delegate, _supplyDex);
        _mint(_addressAirdrop, _supplyAirdrop);
        _mint(_addressTeam, _supplyTeam);
    }
}
