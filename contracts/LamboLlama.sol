// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./oftV1/OFTCore.sol";
import "./oftV1/interfaces/IOFT.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract LamboLlama is OFTCore, IOFT, ERC20, ERC20Permit {
    constructor(
        uint256 _supply,
        address _delegate,
        address _lzEndpointAddress
    )
        ERC20("LamboLlama", "LLL")
        ERC20Permit("LamboLlama")
        Ownable(_delegate)
        OFTCore(_lzEndpointAddress)
    {
        _mint(_delegate, _supply);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(OFTCore, IERC165) returns (bool) {
        return
            interfaceId == type(IOFT).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function token() public view virtual override returns (address) {
        return address(this);
    }

    function circulatingSupply() public view virtual override returns (uint) {
        return totalSupply();
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint _amount
    ) internal virtual override returns (uint) {
        address spender = _msgSender();
        if (_from != spender) _spendAllowance(_from, spender, _amount);
        _burn(_from, _amount);
        return _amount;
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint _amount
    ) internal virtual override returns (uint) {
        _mint(_toAddress, _amount);
        return _amount;
    }
}
