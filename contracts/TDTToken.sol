pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract TDTToken is Initializable, OwnableUpgradeable, ERC20Upgradeable, ReentrancyGuardUpgradeable {

    uint256 public scalingFactor;
    uint256 public constant thresholdOne = 7e21;    // 7,000
    uint256 public constant thresholdTwo = 4e21;    // 4,000
    uint256 public constant thresholdThree = 3e20;  // 300

    /**
     * @dev Expects to call only once by the deployer.
     */
    function initialize(
        string memory _name,
        string memory _symbol
    ) external initializer {
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        __ReentrancyGuard_init();
        scalingFactor = 1e18;
    }

    /**
     * @dev Hook that is called before any transfer of tokens, at here, we would like to
     *      burn token and charge fee when `_transfer()`
     */
    function _beforeTransfer(address from, uint256 amount) internal {
        uint256 currentSupply = totalSupply();
        uint256 burnAmount;
        require(amount <= currentSupply, "_beforeTransfer: Too much to transfer!");

        // If 7,000 < total supply <= 10,000, burn fee is 3%, tx fee is 7%
        if (currentSupply > thresholdOne) {
            burnAmount = amount.mul(3).div(100);
        } else if (currentSupply > thresholdTwo) {
            // If 4,000 < total supply <= 7,000, burn fee is 6%, tx fee is 14%
            burnAmount = amount.mul(6).div(100);
        } else if (currentSupply > thresholdThree) {
            // If 300 < total supply <= 4,000, burn fee is 9%, tx fee is 21%
            burnAmount = amount.mul(9).div(100);
        } else {
            // if total supply <= 300, no burn fee, but tx fee is 3%
        }
        _burn(from, burnAmount);
    }

    /**
     * @dev Transfers `amount` tokens from `spender` to `recipient`.
     * @param spender The address of the source account.
     * @param recipient The address of the destination account.
     * @param amount The number of tokens to transfer.
     */
    function _transferTokens(
        address spender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(
            spender != recipient,
            "_transferTokens: Do not self-transfer!"
        );

        if (spender != msg.sender) {
            _approve(
                spender,
                msg.sender,
                allowance(spender, msg.sender).sub(
                    amount,
                    "transferFrom: Transfer amount exceeds allowance!"
                )
            );
        }

        _beforeTransfer(spender, amount);

        _transfer(spender, recipient, amount);

        return true;
    }

    /**
     * @dev Moves `amount` tokens from caller to `recipient`.
     * @param recipient The address of the destination account.
     * @param amount The number of tokens to transfer.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        return _transferTokens(msg.sender, recipient, amount);
    }

    /**
     * @dev Moves `amount` tokens from `spender` to `recipient`.
     * @param spender The address of the source account.
     * @param recipient The address of the destination account.
     * @param amount The number of tokens to transfer.
     */
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        return _transferTokens(spender, recipient, amount);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
