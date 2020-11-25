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
    function _beforeTransfer(address from, uint256 amount, uint256 burnAmount, uint256 fakeSupply) internal {
        uint256 currentSupply = fakeSupply != 0? fakeSupply : totalSupply();
        uint256 totalBurnAmount = burnAmount != 0 ? burnAmount : 0;
        uint256 remainingSpare;
        uint256 fakeSupplyDecreased;
        require(amount <= currentSupply, "_beforeTransfer: Too much to transfer!");

        // If 7,000 < total supply <= 10,000, burn fee is 3%, tx fee is 7%
        if (currentSupply > thresholdOne) {
            remainingSpare = currentSupply.sub(thresholdOne);
            if (remainingSpare > amount) {
                totalBurnAmount = amount.mul(3).div(100).add(totalBurnAmount);
            } else {
                // TODO: need to have a test!
                fakeSupplyDecreased = remainingSpare.mul(3).div(100);
                totalBurnAmount = fakeSupplyDecreased.add(totalBurnAmount);
                fakeSupplyDecreased = totalSupply().sub(fakeSupplyDecreased).sub(remainingSpare);
                _beforeTransfer(from, amount.sub(remainingSpare), totalBurnAmount, fakeSupplyDecreased);
            }
        } else if (currentSupply > thresholdTwo) {
            // If 4,000 < total supply <= 7,000, burn fee is 6%, tx fee is 14%
            remainingSpare = currentSupply.sub(thresholdTwo);
            if (remainingSpare > amount) {
                totalBurnAmount = amount.mul(6).div(100).add(totalBurnAmount);
            } else {
                // TODO:
                fakeSupplyDecreased = remainingSpare.mul(6).div(100);
                totalBurnAmount = fakeSupplyDecreased.add(totalBurnAmount);
                fakeSupplyDecreased = totalSupply().sub(fakeSupplyDecreased).sub(remainingSpare);
                _beforeTransfer(from, amount.sub(remainingSpare), totalBurnAmount, fakeSupplyDecreased);
            }
        } else if (currentSupply > thresholdThree) {
            // If 300 < total supply <= 4,000, burn fee is 9%, tx fee is 21%
            remainingSpare = currentSupply.sub(thresholdThree);
            if (remainingSpare > amount) {
                totalBurnAmount = amount.mul(9).div(100).add(totalBurnAmount);
            } else {
                // TODO:
                fakeSupplyDecreased = remainingSpare.mul(6).div(100);
                totalBurnAmount = fakeSupplyDecreased.add(totalBurnAmount);
                fakeSupplyDecreased = totalSupply().sub(fakeSupplyDecreased).sub(remainingSpare);
                _beforeTransfer(from, amount.sub(remainingSpare), totalBurnAmount, fakeSupplyDecreased);
            }
        } else {
            // if total supply <= 300, no burn fee, but tx fee is 3%
        }
        // TODO:
        require(totalBurnAmount != 0, "_beforeTransfer: Too small to transfer!");
        _burn(from, totalBurnAmount);
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

        _beforeTransfer(spender, amount, 0, 0);

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