pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title SHET Token
 * @notice ERC20 token with additional features:
 * - Owner-controlled minting and burning
 * - Optional transaction fee directed to the developer wallet
 * - White/black listing of addresses
 * - Transaction and wallet holding limits
 * - Basic anti-bot protection on launch
 * - Ability to toggle trading
 */
contract SHET is ERC20, ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    /// @notice initial supply of 1 billion tokens (18 decimals)
    uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18;

    /// @notice developer wallet that receives transaction fees
    address public devWallet;

    /// @notice percentage fee taken on each transfer (e.g., 2)
    uint256 public feePercent = 2;

    /// @notice true if fees are enabled
    bool public feesEnabled = true;

    /// @notice true if trading is enabled
    bool public tradingEnabled = false;

    /// @notice if anti-bot protection is enabled
    bool public antiBotEnabled = true;

    /// @notice block when trading was enabled
    uint256 public launchBlock;

    /// @notice number of blocks after launch with anti-bot restrictions
    uint256 public protectionBlocks = 3;

    /// @notice address -> whitelisted status
    mapping(address => bool) public isWhitelisted;

    /// @notice address -> blacklisted status
    mapping(address => bool) public isBlacklisted;

    /// @notice addresses excluded from fees
    mapping(address => bool) public isExcludedFromFees;

    /// @notice last transaction block for anti-bot logic
    mapping(address => uint256) private _lastTxBlock;

    /// @notice maximum allowed transaction amount
    uint256 public maxTxAmount;

    /// @notice maximum allowed balance per wallet
    uint256 public maxWalletAmount;

    event FeesToggled(bool enabled);
    event TradingToggled(bool enabled);
    event DevWalletUpdated(address indexed newWallet);
    event WhitelistUpdated(address indexed account, bool status);
    event BlacklistUpdated(address indexed account, bool status);
    event FeePercentUpdated(uint256 newFee);

    /**
     * @param _devWallet address that receives transaction fees
     */
    constructor(address _devWallet) ERC20("SHET", "MEM") {
        require(_devWallet != address(0), "Dev wallet zero");
        devWallet = _devWallet;
        _mint(msg.sender, INITIAL_SUPPLY);
        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[_devWallet] = true;
        maxTxAmount = INITIAL_SUPPLY / 100; // 1% of total supply
        maxWalletAmount = INITIAL_SUPPLY / 50; // 2% of total supply
    }

    /**
     * @notice internal transfer with fee and limits logic
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(!isBlacklisted[sender] && !isBlacklisted[recipient], "Blacklisted");

        if (!tradingEnabled) {
            require(
                isWhitelisted[sender] ||
                    isWhitelisted[recipient] ||
                    sender == owner() ||
                    recipient == owner(),
                "Trading disabled"
            );
        }

        if (antiBotEnabled && tradingEnabled && block.number < launchBlock + protectionBlocks) {
            require(_lastTxBlock[sender] != block.number, "One tx per block");
            require(_lastTxBlock[recipient] != block.number, "One tx per block");
            _lastTxBlock[sender] = block.number;
            _lastTxBlock[recipient] = block.number;
        }

        if (sender != owner() && recipient != owner()) {
            require(amount <= maxTxAmount, "Tx limit");
            if (recipient != devWallet && recipient != address(0)) {
                require(balanceOf(recipient) + amount <= maxWalletAmount, "Wallet limit");
            }
        }

        uint256 feeAmount = 0;
        if (feesEnabled && !isExcludedFromFees[sender] && !isExcludedFromFees[recipient]) {
            feeAmount = (amount * feePercent) / 100;
            super._transfer(sender, devWallet, feeAmount);
        }

        super._transfer(sender, recipient, amount - feeAmount);
    }

    /**
     * @notice mint new tokens to an address (owner only)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice toggle transaction fees
     */
    function toggleFees(bool _enabled) external onlyOwner {
        feesEnabled = _enabled;
        emit FeesToggled(_enabled);
    }

    /**
     * @notice toggle trading on/off
     */
    function toggleTrading(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
        if (_enabled) {
            launchBlock = block.number;
        }
        emit TradingToggled(_enabled);
    }

    /**
     * @notice update developer wallet address
     */
    function setDevWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Zero address");
        devWallet = _wallet;
        emit DevWalletUpdated(_wallet);
    }

    /**
     * @notice add or remove account from whitelist
     */
    function setWhitelist(address account, bool status) external onlyOwner {
        isWhitelisted[account] = status;
        emit WhitelistUpdated(account, status);
    }

    /**
     * @notice add or remove account from blacklist
     */
    function setBlacklist(address account, bool status) external onlyOwner {
        isBlacklisted[account] = status;
        emit BlacklistUpdated(account, status);
    }

    /**
     * @notice exclude or include account from fees
     */
    function setExcludedFromFees(address account, bool status) external onlyOwner {
        isExcludedFromFees[account] = status;
    }

    /**
     * @notice set maximum transaction amount
     */
    function setMaxTxAmount(uint256 amount) external onlyOwner {
        maxTxAmount = amount;
    }

    /**
     * @notice set maximum wallet holding amount
     */
    function setMaxWalletAmount(uint256 amount) external onlyOwner {
        maxWalletAmount = amount;
    }

    /**
     * @notice update transaction fee percent (0-10)
     */
    function setFeePercent(uint256 percent) external onlyOwner {
        require(percent <= 10, "Fee too high");
        feePercent = percent;
        emit FeePercentUpdated(percent);
    }

    /**
     * @notice disable anti-bot protection forever
     */
    function disableAntiBot() external onlyOwner {
        antiBotEnabled = false;
    }
}

