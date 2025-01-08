// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount(uint256 total_, uint8 percentage_) internal pure returns (uint256 percentAmount_) {
        return div(mul(total_, percentage_), 1000);
    }

    function substractPercentage(uint256 total_, uint8 percentageToSub_) internal pure returns (uint256 result_) {
        return sub(total_, div(mul(total_, percentageToSub_), 1000));
    }

    function percentageOfTotal(uint256 part_, uint256 total_) internal pure returns (uint256 percent_) {
        return div(mul(part_, 100), total_);
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing(uint256 payment_, uint256 multiplier_) internal pure returns (uint256) {
        return sqrrt(mul(multiplier_, payment_));
    }

    function bondingCurve(uint256 supply_, uint256 multiplier_) internal pure returns (uint256) {
        return mul(multiplier_, supply_);
    }
}

abstract contract ERC20 is IERC20 {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    // TODO comment actual hash value.
    bytes32 private constant ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256("ERC20Token");

    // Present in ERC777
    mapping(address => uint256) internal _balances;

    // Present in ERC777
    mapping(address => mapping(address => uint256)) internal _allowances;

    // Present in ERC777
    uint256 internal _totalSupply;

    // Present in ERC777
    string internal _name;

    // Present in ERC777
    string internal _symbol;

    // Present in ERC777
    uint8 internal _decimals;

    uint256 public MaxSupply;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        MaxSupply = 115000000 * (10 **  decimals_);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account_, uint256 amount_) internal virtual {
        require(_totalSupply.add(amount_) <= MaxSupply, "ERC20: mint amount exceeds max supply");
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(this), account_, amount_);
        _totalSupply = _totalSupply.add(amount_);
        _balances[account_] = _balances[account_].add(amount_);
        emit Transfer(address(this), account_, amount_);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);

        MaxSupply = MaxSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal virtual {}
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

interface IERC2612Permit {
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    

    constructor() {
        
    }

    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
        virtual
        override
    {
        require(block.timestamp <= deadline, "Permit: expired deadline");
        uint256 chainID;
        assembly {
            chainID := chainid()
        }
        bytes32 DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );

        uint c = _nonces[owner].current();
        bytes32 hashStruct;
        
        hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, c, deadline));
        

        bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

        address signer = _hash.recover(v, r, s);
        require(signer != address(0) && signer == owner, "ZeroSwapPermit: Invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }
}

contract VaultOwned is AccessControl {
    bytes32 public constant MINT = keccak256("MINT");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyVault() {
        require(hasRole(MINT, msg.sender), "VaultOwned: caller is not the Vault");
        _;
    }
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IFeeReceiver {
    function onReceivedFee(uint256 fee) external;

    function triggerSwapFeeForLottery(uint256 amount) external;
}

interface IRewardPool {
    function participate(address user, uint256 qualifiedPaid) external;
}

contract WebKeyDAOERC20Token is ERC20Permit, VaultOwned {
    using SafeMath for uint256;

    constructor() ERC20("WebKey DAO", "wkeyDAO", 9) {}

    function mint(address account_, uint256 amount_) external onlyVault {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal virtual {
        uint256 decreasedAllowance_ =
            allowance(account_, msg.sender).sub(amount_, "ERC20: burn amount exceeds allowance");

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeRouter02 {
    function factory() external pure returns (address);
}


contract WKEYDAO is WebKeyDAOERC20Token {
    using SafeMath for uint256;

    address public mainPair;
    address public feeReceiver;
    address public buyFeeReceiver;


    uint256 public constant PRECISION = 100 * 1e3;
    uint256 public feeRatio = 3 * 1e3;
    uint256 public buyFeeRatio;

    bytes32 public constant INTERN_SYSTEM = keccak256("INTERN_SYSTEM");

    event FeeRatioChanged(uint8 ratioType,uint256 ratio);
    event FeeTaken(address indexed payer, address indexed receiver, uint256 left, uint256 fee);

    modifier onlyDefaultAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _;
    }

    constructor(address _feeReceiver, address _buyFeeReceiver, uint _buyFeeRatio) WebKeyDAOERC20Token() {
        require(_feeReceiver != address(0), "Invalid fee receiver");
        require(_buyFeeReceiver != address(0), "Invalid buy fee receiver");
        require(_buyFeeRatio <= PRECISION, "Invalid buy fee ratio");

        feeReceiver = _feeReceiver;
        buyFeeReceiver = _buyFeeReceiver;
        buyFeeRatio = _buyFeeRatio ;

        _setupRole(DEFAULT_ADMIN_ROLE,msg.sender);
        _setupRole(INTERN_SYSTEM,msg.sender);
        _setupRole(INTERN_SYSTEM,_feeReceiver);
    }

    function setMainPair(address pair) external onlyDefaultAdmin {
        mainPair = pair;
    }

    function setRatio(uint8 ratioType,uint256 ratio) external onlyDefaultAdmin {
        require(ratio <= PRECISION, "Exceeds precision");
        if(ratioType ==0){
            buyFeeRatio = ratio;
        } else {
            feeRatio = ratio;
        }
        emit FeeRatioChanged(ratioType,ratio);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        
        _beforeTokenTransfer(sender, recipient, amount);
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        
        // take fee when non-whitelist users trade
        if (_isTradeAndNotInSystem(sender, recipient)) {
            // buyer or remove lp
            
            if (sender == mainPair) {
                uint buyFee = amount.mul(buyFeeRatio).div(PRECISION);
                
                if(buyFee>0){
                    amount = amount - buyFee;
                    _balances[buyFeeReceiver] += buyFee;
                    emit Transfer(sender, buyFeeReceiver, buyFee);
                }
            }
            // seller or add lp
            else if(recipient == mainPair){
                // take fee
                uint256 fee = amount.mul(feeRatio).div(PRECISION);
                if (fee > 0) {
                    amount = amount - fee;
                    _balances[feeReceiver] += fee;
                    emit Transfer(sender, feeReceiver, fee);
                    emit FeeTaken(sender, feeReceiver, amount, fee);
                    IFeeReceiver(feeReceiver).triggerSwapFeeForLottery(fee);
                }
            }
        }
        
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(sender, recipient, amount);
    }

    function _isTradeAndNotInSystem(address _from, address _to) internal view returns (bool) {
        return (_from == mainPair && !hasRole(INTERN_SYSTEM,_to)) || (_to == mainPair && !hasRole(INTERN_SYSTEM,_from));
    }
}
