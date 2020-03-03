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
  function deposit(uint256 _amount) external;
}

// Solidity Interface

interface ICurveFiv1 {
  function remove_liquidity(
    uint256 _amount,
    uint256 deadline,
    uint256[2] calldata min_amounts
  ) external;
}

interface ICurveFiv2 {
  function remove_liquidity(
    uint256 _amount,
    uint256[3] calldata min_amounts
  ) external;
}

interface Compound {
    function mint ( uint256 mintAmount ) external returns ( uint256 );
    function redeem(uint256 redeemTokens) external returns (uint256);
    function exchangeRateStored() external view returns (uint);
}


interface ICurveFiv3 {
  function add_liquidity(
    uint256[4] calldata amounts,
    uint256 min_mint_amount
  ) external;
}

contract yCurveZapSwap is ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address public DAI;
  address public cDAI;
  address public yDAI;
  address public USDC;
  address public cUSDC;
  address public yUSDC;
  address public USDT;
  address public yUSDT;
  address public SWAPv1;
  address public CURVEv1;
  address public SWAPv2;
  address public CURVEv2;
  address public SWAPv3;
  address public CURVEv3;

  constructor () public {
    DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    yDAI = address(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01);
    cDAI = address(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);

    USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    yUSDC = address(0xd6aD7a6750A7593E092a9B218d66C0A814a3436e);
    cUSDC = address(0x39AA39c021dfbaE8faC545936693aC917d5E7563);

    USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    yUSDT = address(0x83f798e925BcD4017Eb265844FDDAbb448f1707D);

    SWAPv1 = address(0x2e60CF74d81ac34eB21eEff58Db4D385920ef419);
    CURVEv1 = address(0x3740fb63ab7a09891d7c0d4299442A551D06F5fD);

    SWAPv2 = address(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);
    CURVEv2 = address(0x9fC689CCaDa600B6DF723D9E47D84d76664a1F23);

    SWAPv3 = address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
    CURVEv3 = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8);

    approveToken();
  }

  function() external payable {

  }

  function withdrawCompound(address token, uint amount) internal {
      require(Compound(token).redeem(amount) == 0, "COMPOUND: withdraw failed");
  }

  function approveToken() public {
      IERC20(DAI).safeApprove(yDAI, uint(-1));
      IERC20(yDAI).safeApprove(SWAPv3, uint(-1));

      IERC20(USDC).safeApprove(yUSDC, uint(-1));
      IERC20(yUSDC).safeApprove(SWAPv3, uint(-1));

      IERC20(USDT).safeApprove(yUSDT, uint(-1));
      IERC20(yUSDT).safeApprove(SWAPv3, uint(-1));

  }

  function swapv1tov3(uint256 _amount)
      external
      nonReentrant
  {
      require(_amount > 0, "curvev1 must be greater than 0");
      IERC20(CURVEv1).safeTransferFrom(msg.sender, address(this), _amount);
      ICurveFiv1(SWAPv1).remove_liquidity(_amount, now.add(1800), [uint256(0),0]);
      require(IERC20(CURVEv1).balanceOf(address(this)) == 0, "CURVE remainder");

      if (IERC20(cDAI).balanceOf(address(this)) > 0) {
        withdrawCompound(cDAI, IERC20(cDAI).balanceOf(address(this)));
      }
      if (IERC20(cUSDC).balanceOf(address(this)) > 0) {
        withdrawCompound(cUSDC, IERC20(cUSDC).balanceOf(address(this)));
      }

      uint256 _dai = IERC20(DAI).balanceOf(address(this));
      uint256 _usdc = IERC20(USDC).balanceOf(address(this));

      require(_dai > 0 || _usdc > 0, "no underlying found");

      if (_dai > 0) {
        yERC20(yDAI).deposit(_dai);
        require(IERC20(DAI).balanceOf(address(this)) == 0, "dai remainder");
      }

      if (_usdc > 0) {
        yERC20(yUSDC).deposit(_usdc);
        require(IERC20(USDC).balanceOf(address(this)) == 0, "usdc remainder");
      }

      ICurveFiv3(SWAPv3).add_liquidity([
        IERC20(yDAI).balanceOf(address(this)),
        IERC20(yUSDC).balanceOf(address(this)),0,0],0);

      require(IERC20(yDAI).balanceOf(address(this)) == 0, "yDAI remainder");
      require(IERC20(yUSDC).balanceOf(address(this)) == 0, "yUSDC remainder");

      uint256 received = IERC20(CURVEv3).balanceOf(address(this));
      uint256 deposit = _dai.add((_usdc.mul(1e12)));
      uint256 fivePercent = deposit.mul(5).div(100);
      uint256 min = deposit.sub(fivePercent);
      uint256 max = deposit.add(fivePercent);
      require(received <= max && received >= min, "slippage greater than 5%");

      IERC20(CURVEv3).safeTransfer(msg.sender, IERC20(CURVEv3).balanceOf(address(this)));
      require(IERC20(CURVEv3).balanceOf(address(this)) == 0, "CURVEv3 remainder");
  }

  function swapv2tov3(uint256 _amount)
      external
      nonReentrant
  {
      require(_amount > 0, "curvev1 must be greater than 0");
      IERC20(CURVEv2).safeTransferFrom(msg.sender, address(this), _amount);
      ICurveFiv2(SWAPv2).remove_liquidity(_amount, [uint256(0),0,0]);
      require(IERC20(CURVEv2).balanceOf(address(this)) == 0, "CURVE remainder");

      if (IERC20(cDAI).balanceOf(address(this)) > 0) {
        withdrawCompound(cDAI, IERC20(cDAI).balanceOf(address(this)));
      }
      if (IERC20(cUSDC).balanceOf(address(this)) > 0) {
        withdrawCompound(cUSDC, IERC20(cUSDC).balanceOf(address(this)));
      }

      uint256 _dai = IERC20(DAI).balanceOf(address(this));
      uint256 _usdc = IERC20(USDC).balanceOf(address(this));
      uint256 _usdt = IERC20(USDT).balanceOf(address(this));

      require(_dai > 0 || _usdc > 0 || _usdt > 0, "no underlying found");

      if (_dai > 0) {
        yERC20(yDAI).deposit(_dai);
        require(IERC20(DAI).balanceOf(address(this)) == 0, "dai remainder");
      }

      if (_usdc > 0) {
        yERC20(yUSDC).deposit(_usdc);
        require(IERC20(USDC).balanceOf(address(this)) == 0, "usdc remainder");
      }

      if (_usdt > 0) {
        yERC20(yUSDT).deposit(_usdt);
        require(IERC20(USDT).balanceOf(address(this)) == 0, "usdc remainder");
      }

      ICurveFiv3(SWAPv3).add_liquidity([
        IERC20(yDAI).balanceOf(address(this)),
        IERC20(yUSDC).balanceOf(address(this)),
        IERC20(yUSDT).balanceOf(address(this)),0],0);

      require(IERC20(yDAI).balanceOf(address(this)) == 0, "yDAI remainder");
      require(IERC20(yUSDC).balanceOf(address(this)) == 0, "yUSDC remainder");
      require(IERC20(yUSDT).balanceOf(address(this)) == 0, "yUSDT remainder");

      uint256 received = IERC20(CURVEv3).balanceOf(address(this));
      uint256 deposit = _dai.add((_usdc.mul(1e12))).add((_usdt.mul(1e12)));
      uint256 fivePercent = deposit.mul(5).div(100);
      uint256 min = deposit.sub(fivePercent);
      uint256 max = deposit.add(fivePercent);
      require(received <= max && received >= min, "slippage greater than 5%");

      IERC20(CURVEv3).safeTransfer(msg.sender, IERC20(CURVEv3).balanceOf(address(this)));
      require(IERC20(CURVEv3).balanceOf(address(this)) == 0, "CURVEv3 remainder");
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
