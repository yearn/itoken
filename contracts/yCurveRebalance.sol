pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

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

interface yERC20 {
  function rebalance() external;
  function provider() external returns (uint8);
  function recommend() external returns (uint8);
  function balance() external view returns (uint256);
}

contract yTokenRebalance is ReentrancyGuard, Ownable {
  using Address for address;
  using SafeMath for uint256;

  address public DAIv2;
  address public DAIv3;
  address public USDCv2;
  address public USDCv3;
  address public USDTv2;
  address public USDTv3;
  address public TUSDv2;

  constructor () public {
    DAIv2 = address(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01);
    DAIv3 = address(0xC2cB1040220768554cf699b0d863A3cd4324ce32);
    USDCv2 = address(0xd6aD7a6750A7593E092a9B218d66C0A814a3436e);
    USDCv3 = address(0x26EA744E5B887E5205727f55dFBE8685e3b21951);
    USDTv2 = address(0x83f798e925BcD4017Eb265844FDDAbb448f1707D);
    USDTv3 = address(0xE6354ed5bC4b393a5Aad09f21c46E101e692d447);
    TUSDv2 = address(0x73a052500105205d34Daf004eAb301916DA8190f);
  }
  function balanceDAIv2() public view returns (uint256) {
    return yERC20(DAIv2).balance();
  }
  function balanceDAIv3() public view returns (uint256) {
    return yERC20(DAIv3).balance();
  }
  function balanceUSDCv2() public view returns (uint256) {
    return yERC20(USDCv2).balance();
  }
  function balanceUSDCv3() public view returns (uint256) {
    return yERC20(USDCv3).balance();
  }
  function balanceUSDTv2() public view returns (uint256) {
    return yERC20(USDTv2).balance();
  }
  function balanceUSDTv3() public view returns (uint256) {
    return yERC20(USDTv3).balance();
  }
  function balanceTUSDTv2() public view returns (uint256) {
    return yERC20(TUSDv2).balance();
  }
  function rebalance() public {
      if (yERC20(DAIv2).provider() == yERC20(DAIv2).recommend()) {
        yERC20(DAIv2).rebalance();
      }
      if (yERC20(DAIv3).provider() == yERC20(DAIv3).recommend()) {
        yERC20(DAIv3).rebalance();
      }
      if (yERC20(USDCv2).provider() == yERC20(USDCv2).recommend()) {
        yERC20(USDCv2).rebalance();
      }
      if (yERC20(USDCv3).provider() == yERC20(USDCv3).recommend()) {
        yERC20(USDCv3).rebalance();
      }
      if (yERC20(USDTv2).provider() == yERC20(USDTv2).recommend()) {
        yERC20(USDTv2).rebalance();
      }
      if (yERC20(USDTv3).provider() == yERC20(USDTv3).recommend()) {
        yERC20(USDTv3).rebalance();
      }
      if (yERC20(TUSDv2).provider() == yERC20(TUSDv2).recommend()) {
        yERC20(TUSDv2).rebalance();
      }
  }
}
