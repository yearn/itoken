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

interface yERC20 {
  function withdraw(uint256 _amount) external;
}

// Solidity Interface

interface ICurveFi {

  function remove_liquidity(
    uint256 _amount,
    uint256[4] calldata amounts
  ) external;
  function exchange(
    int128 from, int128 to, uint256 _from_amount, uint256 _min_to_amount
  ) external;
}

contract yCurveZapOutV4 is ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public DAI;
  address public yDAI;
  address public USDC;
  address public yUSDC;
  address public USDT;
  address public yUSDT;
  address public BUSD;
  address public yBUSD;
  address public SWAP;
  address public CURVE;

  constructor () public {
    DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    yDAI = address(0xC2cB1040220768554cf699b0d863A3cd4324ce32);

    USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    yUSDC = address(0x26EA744E5B887E5205727f55dFBE8685e3b21951);

    USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    yUSDT = address(0xE6354ed5bC4b393a5Aad09f21c46E101e692d447);

    BUSD = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    yBUSD = address(0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE);

    SWAP = address(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);
    CURVE = address(0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B);

    approveToken();
  }

  function() external payable {

  }

  function approveToken() public {
      IERC20(yDAI).safeApprove(SWAP, uint(-1));
      IERC20(yUSDC).safeApprove(SWAP, uint(-1));
      IERC20(yUSDT).safeApprove(SWAP, uint(-1));
      IERC20(yBUSD).safeApprove(SWAP, uint(-1));
  }

  function checkSlippage(uint256 _amount, address _token, uint256 _dec) public view returns (bool) {
    uint256 received = (IERC20(_token).balanceOf(address(this))).mul(_dec);
    uint256 fivePercent = _amount.mul(5).div(100);
    uint256 min = _amount.sub(fivePercent);
    uint256 max = _amount.add(fivePercent);
    require(received <= max && received >= min, "slippage greater than 5%");
    return true;
  }

  function withdrawCurve(uint256 _amount) public {
    require(_amount > 0, "deposit must be greater than 0");
    IERC20(CURVE).safeTransferFrom(msg.sender, address(this), _amount);
    ICurveFi(SWAP).remove_liquidity(IERC20(CURVE).balanceOf(address(this)), [uint256(0),0,0,0]);
    require(IERC20(CURVE).balanceOf(address(this)) == 0, "CURVE remainder");
  }

  function withdrawDAI(uint256 _amount)
      external
      nonReentrant
  {
      withdrawCurve(_amount);

      uint256 _ydai = IERC20(yDAI).balanceOf(address(this));
      uint256 _yusdc = IERC20(yUSDC).balanceOf(address(this));
      uint256 _yusdt = IERC20(yUSDT).balanceOf(address(this));
      uint256 _ybusd = IERC20(yBUSD).balanceOf(address(this));

      require(_ydai > 0 || _yusdc > 0 || _yusdt > 0 || _ybusd > 0, "no y.tokens found");

      if (_yusdc > 0) {
        ICurveFi(SWAP).exchange(1, 0, _yusdc, 0);
        require(IERC20(yUSDC).balanceOf(address(this)) == 0, "y.USDC remainder");
      }
      if (_yusdt > 0) {
        ICurveFi(SWAP).exchange(2, 0, _yusdt, 0);
        require(IERC20(yUSDT).balanceOf(address(this)) == 0, "y.USDT remainder");
      }
      if (_ybusd > 0) {
        ICurveFi(SWAP).exchange(3, 0, _ybusd, 0);
        require(IERC20(yBUSD).balanceOf(address(this)) == 0, "y.BUSD remainder");
      }

      yERC20(yDAI).withdraw(IERC20(yDAI).balanceOf(address(this)));
      require(IERC20(yDAI).balanceOf(address(this)) == 0, "y.DAI remainder");

      checkSlippage(_amount, DAI, 1);

      IERC20(DAI).safeTransfer(msg.sender, IERC20(DAI).balanceOf(address(this)));
      require(IERC20(DAI).balanceOf(address(this)) == 0, "DAI remainder");
  }

  function withdrawUSDC(uint256 _amount)
      external
      nonReentrant
  {
      withdrawCurve(_amount);

      uint256 _ydai = IERC20(yDAI).balanceOf(address(this));
      uint256 _yusdc = IERC20(yUSDC).balanceOf(address(this));
      uint256 _yusdt = IERC20(yUSDT).balanceOf(address(this));
      uint256 _ybusd = IERC20(yBUSD).balanceOf(address(this));

      require(_ydai > 0 || _yusdc > 0 || _yusdt > 0 || _ybusd > 0, "no y.tokens found");

      if (_ydai > 0) {
        ICurveFi(SWAP).exchange(0, 1, _ydai, 0);
        require(IERC20(yDAI).balanceOf(address(this)) == 0, "y.DAI remainder");
      }
      if (_yusdt > 0) {
        ICurveFi(SWAP).exchange(2, 1, _yusdt, 0);
        require(IERC20(yUSDT).balanceOf(address(this)) == 0, "y.USDT remainder");
      }
      if (_ybusd > 0) {
        ICurveFi(SWAP).exchange(3, 1, _ybusd, 0);
        require(IERC20(yBUSD).balanceOf(address(this)) == 0, "y.BUSD remainder");
      }

      yERC20(yUSDC).withdraw(IERC20(yUSDC).balanceOf(address(this)));
      require(IERC20(yUSDC).balanceOf(address(this)) == 0, "y.USDC remainder");

      checkSlippage(_amount, USDC, 1e12);

      IERC20(USDC).safeTransfer(msg.sender, IERC20(USDC).balanceOf(address(this)));
      require(IERC20(USDC).balanceOf(address(this)) == 0, "USDC remainder");
  }

  function withdrawUSDT(uint256 _amount)
      external
      nonReentrant
  {
      withdrawCurve(_amount);

      uint256 _ydai = IERC20(yDAI).balanceOf(address(this));
      uint256 _yusdc = IERC20(yUSDC).balanceOf(address(this));
      uint256 _yusdt = IERC20(yUSDT).balanceOf(address(this));
      uint256 _ybusd = IERC20(yBUSD).balanceOf(address(this));

      require(_ydai > 0 || _yusdc > 0 || _yusdt > 0 || _ybusd > 0, "no y.tokens found");

      if (_ydai > 0) {
        ICurveFi(SWAP).exchange(0, 2, _ydai, 0);
        require(IERC20(yDAI).balanceOf(address(this)) == 0, "y.DAI remainder");
      }
      if (_yusdc > 0) {
        ICurveFi(SWAP).exchange(1, 2, _yusdc, 0);
        require(IERC20(yUSDC).balanceOf(address(this)) == 0, "y.USDC remainder");
      }
      if (_ybusd > 0) {
        ICurveFi(SWAP).exchange(3, 2, _ybusd, 0);
        require(IERC20(yBUSD).balanceOf(address(this)) == 0, "y.BUSD remainder");
      }

      yERC20(yUSDT).withdraw(IERC20(yUSDT).balanceOf(address(this)));
      require(IERC20(yUSDT).balanceOf(address(this)) == 0, "y.USDT remainder");

      checkSlippage(_amount, USDT, 1e12);

      IERC20(USDT).safeTransfer(msg.sender, IERC20(USDT).balanceOf(address(this)));
      require(IERC20(USDT).balanceOf(address(this)) == 0, "USDT remainder");
  }

  function withdrawBUSD(uint256 _amount)
      external
      nonReentrant
  {
      withdrawCurve(_amount);

      uint256 _ydai = IERC20(yDAI).balanceOf(address(this));
      uint256 _yusdc = IERC20(yUSDC).balanceOf(address(this));
      uint256 _yusdt = IERC20(yUSDT).balanceOf(address(this));
      uint256 _ybusd = IERC20(yBUSD).balanceOf(address(this));

      require(_ydai > 0 || _yusdc > 0 || _yusdt > 0 || _ybusd > 0, "no y.tokens found");

      if (_ydai > 0) {
        ICurveFi(SWAP).exchange(0, 3, _ydai, 0);
        require(IERC20(yDAI).balanceOf(address(this)) == 0, "y.DAI remainder");
      }
      if (_yusdc > 0) {
        ICurveFi(SWAP).exchange(1, 3, _yusdc, 0);
        require(IERC20(yUSDC).balanceOf(address(this)) == 0, "y.USDC remainder");
      }
      if (_yusdt > 0) {
        ICurveFi(SWAP).exchange(2, 3, _yusdt, 0);
        require(IERC20(yUSDT).balanceOf(address(this)) == 0, "y.USDT remainder");
      }

      yERC20(yBUSD).withdraw(IERC20(yBUSD).balanceOf(address(this)));
      require(IERC20(yBUSD).balanceOf(address(this)) == 0, "y.BUSD remainder");

      checkSlippage(_amount, BUSD, 1);

      IERC20(BUSD).safeTransfer(msg.sender, IERC20(BUSD).balanceOf(address(this)));
      require(IERC20(BUSD).balanceOf(address(this)) == 0, "BUSD remainder");
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
