pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ICurveFi {
  function exchange_underlying(
    int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
  ) external;
}

contract Structs {
    struct Val {
        uint256 value;
    }

    enum ActionType {
      Deposit,   // supply tokens
      Withdraw,  // borrow tokens
      Transfer,  // transfer balance between accounts
      Buy,       // buy an amount of some token (externally)
      Sell,      // sell an amount of some token (externally)
      Trade,     // trade tokens against another account
      Liquidate, // liquidate an undercollateralized or expiring account
      Vaporize,  // use excess tokens to zero-out a completely negative account
      Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei // the amount is denominated in wei
    }

    enum AssetReference {
        Delta // the amount is given as a delta from the current value
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

contract DyDx is Structs {
    function getAccountWei(Info memory account, uint256 marketId) public view returns (Wei memory);
    function operate(Info[] memory, ActionArgs[] memory) public;
}

interface OneSplit {

    function goodSwap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        uint256 parts,
        uint256 disableFlags // 1 - Uniswap, 2 - Kyber, 4 - Bancor, 8 - Oasis, 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken
    )
        external
        payable;
}


contract CurveFlash is ReentrancyGuard, Ownable, Structs {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address constant public one = address(0x64D04c6dA4B0bC0109D7fC29c9D09c802C061898);
  address public constant dydx = address(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

  address public constant dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address public constant usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address public constant usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);

  uint256 public constant FLAG_DISABLE_UNISWAP = 0x01;
  uint256 public constant FLAG_DISABLE_KYBER = 0x02;
  uint256 public constant FLAG_ENABLE_KYBER_UNISWAP_RESERVE = 0x100000000; // Turned off by default
  uint256 public constant FLAG_ENABLE_KYBER_OASIS_RESERVE = 0x200000000; // Turned off by default
  uint256 public constant FLAG_ENABLE_KYBER_BANCOR_RESERVE = 0x400000000; // Turned off by default
  uint256 public constant FLAG_DISABLE_BANCOR = 0x04;
  uint256 public constant FLAG_DISABLE_OASIS = 0x08;
  uint256 public constant FLAG_DISABLE_COMPOUND = 0x10;
  uint256 public constant FLAG_DISABLE_FULCRUM = 0x20;
  uint256 public constant FLAG_DISABLE_CHAI = 0x40;
  uint256 public constant FLAG_DISABLE_AAVE = 0x80;
  uint256 public constant FLAG_DISABLE_SMART_TOKEN = 0x100;
  uint256 public constant FLAG_ENABLE_MULTI_PATH_ETH = 0x200; // Turned off by default
  uint256 public constant FLAG_DISABLE_BDAI = 0x400;
  uint256 public constant FLAG_DISABLE_IEARN = 0x800;
  uint256 public constant FLAG_DISABLE_CURVE_COMPOUND = 0x1000;
  uint256 public constant FLAG_DISABLE_CURVE_USDT = 0x2000;
  uint256 public constant FLAG_DISABLE_CURVE_Y = 0x4000;
  uint256 public constant FLAG_DISABLE_CURVE_BINANCE = 0x8000;

  uint256 public constant DISABLED = FLAG_DISABLE_UNISWAP
  +FLAG_DISABLE_KYBER
  +FLAG_DISABLE_BANCOR
  +FLAG_DISABLE_OASIS
  +FLAG_DISABLE_COMPOUND
  +FLAG_DISABLE_FULCRUM
  +FLAG_DISABLE_CHAI
  +FLAG_DISABLE_AAVE
  +FLAG_DISABLE_SMART_TOKEN
  +FLAG_DISABLE_BDAI
  +FLAG_DISABLE_CURVE_COMPOUND
  +FLAG_DISABLE_CURVE_USDT
  +FLAG_DISABLE_IEARN;

  constructor () public {
    approveToken();
  }

  function approveToken() public {
      IERC20(dai).safeApprove(dydx, uint(-1));

      IERC20(dai).safeApprove(one, uint(-1));
      IERC20(usdc).safeApprove(one, uint(-1));
      IERC20(usdt).safeApprove(one, uint(-1));
  }

  function max() public {
    trade(IERC20(dai).balanceOf(dydx));
  }

  function trade(uint256 amount) public {
    Info[] memory infos = new Info[](1);
    ActionArgs[] memory args = new ActionArgs[](3);

    infos[0] = Info(address(this), 0);

    AssetAmount memory wamt = AssetAmount(false, AssetDenomination.Wei, AssetReference.Delta, amount);
    ActionArgs memory withdraw;
    withdraw.actionType = ActionType.Withdraw;
    withdraw.accountId = 0;
    withdraw.amount = wamt;
    withdraw.primaryMarketId = 3;
    withdraw.otherAddress = address(this);

    args[0] = withdraw;

    ActionArgs memory call;
    call.actionType = ActionType.Call;
    call.accountId = 0;
    call.otherAddress = address(this);

    args[1] = call;

    ActionArgs memory deposit;
    AssetAmount memory damt = AssetAmount(true, AssetDenomination.Wei, AssetReference.Delta, amount.add(1));
    deposit.actionType = ActionType.Deposit;
    deposit.accountId = 0;
    deposit.amount = damt;
    deposit.primaryMarketId = 3;
    deposit.otherAddress = address(this);

    args[2] = deposit;

    DyDx(dydx).operate(infos, args);
  }

  function callFunction(
      address sender,
      Info memory accountInfo,
      bytes memory data
  ) public {
    OneSplit(one).goodSwap(dai, usdt, IERC20(dai).balanceOf(address(this)), 1, 2, DISABLED);
    OneSplit(one).goodSwap(usdt, dai, IERC20(usdt).balanceOf(address(this)), 1, 2, DISABLED);
    //OneSplit(one).goodSwap(usdc, dai, IERC20(usdc).balanceOf(address(this)), 1, 4, DISABLED);
  }

  function() external payable {

  }

  // incase of half-way error
  function inCaseTokenGetsStuck(IERC20 _TokenAddress) onlyOwner public {
      uint qty = _TokenAddress.balanceOf(address(this));
      _TokenAddress.safeTransfer(msg.sender, qty);
  }

  // incase of half-way error
  function inCaseETHGetsStuck() onlyOwner public{
      (bool result, ) = msg.sender.call.value(address(this).balance)("");
      require(result, "transfer of ETH failed");
  }
}
