pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract Token is ERC20Upgradeable {
    constructor(string memory _name, string memory _symbol) public {
        __ERC20_init(_name, _symbol);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
