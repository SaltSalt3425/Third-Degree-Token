pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interface/IERC20Upgradeable.sol";
// TODO: only for debug
import "hardhat/console.sol";

contract TDTToken is Initializable, OwnableUpgradeable, IERC20Upgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public constant thresholdOne = 7e21;    // 7,000
    uint256 public constant thresholdTwo = 4e21;    // 4,000
    uint256 public constant thresholdThree = 3e20;  // 300

    uint256 public constant BASE = 1e18;
    uint256 internal constant internalDecimals = 1e18;

    uint256 public scalingFactor;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    uint256 public initSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    //-------------------------------
    //------------ Events -----------
    //-------------------------------
    // Tokens minted event.
    event Mint(address to, uint256 amount);

    /**
     * @notice Expects to call only once by the deployer.
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     *      a default value of 18.
     */
    function initialize(
        string memory name_,
        string memory symbol_
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        scalingFactor = 1e18;
        name = name_;
        symbol = symbol_;
        decimals = 18;
        initSupply = 0;
    }

    //-------------------------------
    //-------- Math Function --------
    //-------------------------------

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(y).div(BASE);
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x.mul(BASE).div(y);
    }

    function _underlyingToFragment(uint256 amount) internal view returns (uint256) {
        return amount.mul(scalingFactor).div(internalDecimals);
    }

    function _fragmentToUnderlying(uint256 amount) internal view returns (uint256) {
        return amount.mul(internalDecimals).div(scalingFactor);
    }

    /**
     * @notice Computes the current max scaling factor.
     */
    function _maxScalingFactor() internal view returns (uint256) {
        // scaling factor can only go up to 2**256-1 = initSupply * scalingFactor
        // this is used to check if scalingFactor will be too high to compute balances when
        // distrubte tx fee automatically.
        return uint256(-1) / initSupply;
    }

    // function rdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
    //     z = x.mul(BASE).add(y.sub(1)).div(y);
    // }

    // common function
    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) external view override returns (uint256) {
        console.log("msg.sender is", who);
        console.log("msg.sender balance is", _balances[who]);
        console.log("scalingFactor is", scalingFactor);
        return _underlyingToFragment(_balances[who]);
    }

    /**
     * @notice Currently returns the internal storage amount
     * @param who The address to query.
     * @return The underlying balance of the specified address.
     */
    function balanceOfUnderlying(address who) external view returns (uint256) {
        return _balances[who];
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() external view override returns (uint256) {
        return rmul(_totalSupply, scalingFactor);
    }

    function _rebase(uint256 amount) internal {
        uint256 currentSupply = _totalSupply;
        // Get amount in underlying.
        uint256 underlyingValue = _fragmentToUnderlying(amount);
        scalingFactor = scalingFactor.add(rdiv(underlyingValue, currentSupply));
    }

    /**
     * @dev Hook that is called before any transfer of tokens, at here, we would like to
     *      burn token and charge fee when `_transfer()`
     */
    function _afterTransfer(address from, uint256 amount) internal returns (bool) {
        uint256 currentSupply = _totalSupply;
        uint256 burnAmount;
        require(amount <= currentSupply, "_afterTransfer: Too much to transfer!");

        /**
         * Cause tx fee is the same as burn fee, so just use the same variable.
         */
        // If 7,000 < total supply <= 10,000, burn fee is 3%, tx fee is 3%
        if (currentSupply > thresholdOne) {
            burnAmount = amount.mul(3).div(100);
        } else if (currentSupply > thresholdTwo) {
            // If 4,000 < total supply <= 7,000, burn fee is 4%, tx fee is 4%
            burnAmount = amount.mul(4).div(100);
        } else if (currentSupply > thresholdThree) {
            // If 300 < total supply <= 4,000, burn fee is 5%, tx fee is 5%
            burnAmount = amount.mul(5).div(100);
        } else {
            // if total supply <= 300, no burn fee, but tx fee is 3%
            burnAmount = amount.mul(3).div(100);
            _burn(from, burnAmount);
            _rebase(burnAmount);

            return true;
        }
        _burn(from, burnAmount.mul(2));
        _rebase(burnAmount);

        return true;
    }

    /**
     * @notice This is internal function is equivalent to `transfer`.
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     * @param sender The address of the source account.
     * @param recipient The address of the destination account.
     * @param amount The number of tokens to transfer.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "_transfer: Ttransfer from the zero address!");
        require(recipient != address(0), "_transfer: Ttransfer to the zero address!");

        // Get amount in underlying
        uint256 underlyingValue = _fragmentToUnderlying(amount);
        // Transfer token from sender to recipient.
        _balances[sender] = _balances[sender].sub(underlyingValue, "_transfer: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(underlyingValue);
        emit Transfer(sender, recipient, underlyingValue);

        // Burn token and charge fee.
        _afterTransfer(sender, amount);
    }

    /**
     * @notice Underlying balance is stored in `_balances`, so divide by current scaling factor.
     *         This means as scaling factor grows, dust will be untransferrable.
     *         Minimum transfer value == scalingFactor / 1e24;
     * @dev Moves `amount` tokens from caller to `recipient`.
     * @param recipient The address of the destination account.
     * @param amount The number of tokens to transfer.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`.
     * @param sender The address of the source account.
     * @param recipient The address of the destination account.
     * @param amount The number of tokens to transfer.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "transferFrom: transfer amount exceeds allowance"));
        return true;
    }


    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     *      caller.
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     *       the total supply.
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "_mint: mint to the zero address!");

        // get underlying value
        uint256 underlyingValue = _fragmentToUnderlying(amount);

        // make sure the mint didnt push maxScalingFactor too low
        if (_totalSupply != 0) {
            require(
                scalingFactor <= _maxScalingFactor(),
                "_mint: max scaling factor too low"
            );
        }

        // Adds balance.
        _balances[to] = _balances[to].add(underlyingValue);
        // Increases _totalSupply
        _totalSupply = _totalSupply.add(underlyingValue);

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     *      total supply.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "_burn: burn from the zero address");

        // Gets underlying value.
        uint256 underlyingValue = _fragmentToUnderlying(amount);

        _balances[account] = _balances[account].sub(underlyingValue, "_burn: burn amount exceeds balance!");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "_approve: approve from the zero address!");
        require(spender != address(0), "_approve: approve to the zero address!");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "decreaseAllowance: decreased allowance below zero"));
        return true;
    }
}
