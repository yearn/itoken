pragma solidity ^0.5.0;

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

interface yERC20 {
  function getPricePerFullShare() external view returns (uint256);
}

interface CurveFi {
  function get_dy_underlying(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);
  function get_virtual_price() external view returns (uint256);
  function exchange_underlying(
    int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
  ) external;
}

interface Uniswap {
  function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
  function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
}

contract LiquidationOracle is ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address public constant yDAI = address(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01);

  address public constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address public constant yUSDC = address(0xd6aD7a6750A7593E092a9B218d66C0A814a3436e);

  address public constant USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address public constant yUSDT = address(0x83f798e925BcD4017Eb265844FDDAbb448f1707D);

  address public constant TUSD = address(0x0000000000085d4780B73119b644AE5ecd22b376);
  address public constant yTUSD = address(0x73a052500105205d34Daf004eAb301916DA8190f);

  address public constant SUSD = address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
  address public constant ySUSD = address(0xF61718057901F84C4eEC4339EF8f0D86D2B45600);

  address public constant BUSD = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
  address public constant yBUSD = address(0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE);

  address public constant ySWAP = address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
  address public constant sSWAP = address(0x3b12e1fBb468BEa80B492d635976809Bf950186C);
  address public constant bSWAP = address(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);

  address public constant uniDAI = address(0x2a1530C4C41db0B0b2bB646CB5Eb1A67b7158667);


  function getCurveRate(address _token, uint256 _amount) external view returns (uint256) {
    if (_token == DAI) {
      return _amount.div(_amount);
    } else {
      int128 index = getIndex(_token);
      address pool = getPool(_token);
      return CurveFi(pool).get_dy_underlying(index, 0, _amount).div(_amount);
    }
  }
  function getUniswapRate(address _factory, uint256 _amount) external view returns (uint256) {
    if (_factory == DAI) {
      return _amount.div(_amount);
    } else {
      uint256 eth_bought = Uniswap(_factory).getTokenToEthInputPrice(_amount);
      uint256 dai_bought = Uniswap(uniDAI).getEthToTokenInputPrice(eth_bought);
      return dai_bought.div(_amount);
    }
  }

  function getIndex(address _token) public pure returns (int128) {
    if (_token == DAI) {
      return 0;
    } else if (_token == USDC) {
      return 1;
    } else if (_token == USDT) {
      return 2;
    } else if (_token == TUSD) {
      return 3;
    } else if (_token == BUSD) {
      return 4;
    } else if (_token == SUSD) {
      return 4;
    }
  }
  function getPool(address _token) public pure returns (address) {
    if (_token == DAI) {
      return ySWAP;
    } else if (_token == USDC) {
      return ySWAP;
    } else if (_token == USDT) {
      return ySWAP;
    } else if (_token == TUSD) {
      return ySWAP;
    } else if (_token == BUSD) {
      return bSWAP;
    } else if (_token == SUSD) {
      return sSWAP;
    }
  }

  // incase of half-way error
  function inCaseTokenGetsStuck(IERC20 _TokenAddress) onlyOwner public {
      uint qty = _TokenAddress.balanceOf(address(this));
      _TokenAddress.safeTransfer(msg.sender, qty);
  }
}
