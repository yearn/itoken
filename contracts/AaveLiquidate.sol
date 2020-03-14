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

interface Aave {
  function liquidationCall(
        address _collateral,
        address _reserve,
        address _user,
        uint256 _purchaseAmount,
        bool _receiveAToken
    ) external payable;
    function getUserReserveData(address _reserve, address _user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentBorrowBalance,
            uint256 principalBorrowBalance,
            uint256 borrowRateMode,
            uint256 borrowRate,
            uint256 liquidityRate,
            uint256 originationFee,
            uint256 variableBorrowIndex,
            uint256 lastUpdateTimestamp,
            bool usageAsCollateralEnabled
        );
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

interface Oracle {
  function latestAnswer() external view returns (int256);
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

contract AaveLiquidate is ReentrancyGuard, Ownable, Structs {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  address constant public aave = address(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);
  address constant public core = address(0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3);
  address constant public one = address(0x8da6995e8cB3Af3237945a0e628F312f32723a1c);

  address constant public aETH = address(0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04);
  address constant public aDAI = address(0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d);
  address constant public aUSDC = address(0x9bA00D6856a4eDF4665BcA2C2309936572473B7E);
  address constant public aSUSD = address(0x625aE63000f46200499120B906716420bd059240);
  address constant public aTUSD = address(0x4DA9b813057D04BAef4e5800E36083717b4a0341);
  address constant public aUSDT = address(0x71fc860F7D3A592A4a98740e39dB31d25db65ae8);
  address constant public aBAT = address(0xE1BA0FB44CCb0D11b80F92f4f8Ed94CA3fF51D00);
  address constant public aKNC = address(0x9D91BE44C06d373a8a226E1f3b146956083803eB);
  address constant public aLEND = address(0x7D2D3688Df45Ce7C552E19c27e007673da9204B8);
  address constant public aLINK = address(0xA64BD6C70Cb9051F6A9ba1F163Fdc07E0DfB5F84);
  address constant public aMANA = address(0x6FCE4A401B6B80ACe52baAefE4421Bd188e76F6f);
  address constant public aMKR = address(0x7deB5e830be29F91E298ba5FF1356BB7f8146998);
  address constant public aREP = address(0x71010A9D003445aC60C4e6A7017c1E89A477B438);
  address constant public aSNX = address(0x328C4c80BC7aCa0834Db37e6600A6c49E12Da4DE);
  address constant public aWBTC = address(0xFC4B8ED459e00e5400be803A9BB3954234FD50e3);
  address constant public aZRX = address(0x6Fb0855c404E09c47C3fBCA25f08d4E41f9F062f);

  address[16] public aaves = [aETH, aDAI, aUSDC, aSUSD, aTUSD, aUSDT, aBAT, aKNC, aLEND, aLINK, aMANA, aMKR, aREP, aSNX, aWBTC, aZRX];

  address constant public ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  address constant public DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address constant public USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant public SUSD = address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
  address constant public TUSD = address(0x0000000000085d4780B73119b644AE5ecd22b376);
  address constant public USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address constant public BAT = address(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);
  address constant public KNC = address(0xdd974D5C2e2928deA5F71b9825b8b646686BD200);
  address constant public LEND = address(0x80fB784B7eD66730e8b1DBd9820aFD29931aab03);
  address constant public LINK = address(0x514910771AF9Ca656af840dff83E8264EcF986CA);
  address constant public MANA = address(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942);
  address constant public MKR = address(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
  address constant public REP = address(0x1985365e9f78359a9B6AD760e32412f4a445E862);
  address constant public SNX = address(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
  address constant public WBTC = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
  address constant public ZRX = address(0xE41d2489571d322189246DaFA5ebDe1F4699F498);

  address[16] public reserves = [ETH, DAI, USDC, SUSD, TUSD, USDT, BAT, KNC, LEND, LINK, MANA, MKR, REP, SNX, WBTC, ZRX];

  address constant public lETH = address(0x79fEbF6B9F76853EDBcBc913e6aAE8232cFB9De9);
  address constant public lDAI = address(0x037E8F2125bF532F3e228991e051c8A7253B642c);
  address constant public lUSDC = address(0xdE54467873c3BCAA76421061036053e371721708);
  address constant public lSUSD = address(0x6d626Ff97f0E89F6f983dE425dc5B24A18DE26Ea);
  address constant public lTUSD = address(0x73ead35fd6A572EF763B13Be65a9db96f7643577);
  address constant public lUSDT = address(0xa874fe207DF445ff19E7482C746C4D3fD0CB9AcE);
  address constant public lBAT = address(0x9b4e2579895efa2b4765063310Dc4109a7641129);
  address constant public lKNC = address(0xd0e785973390fF8E77a83961efDb4F271E6B8152);
  address constant public lLEND = address(0x1EeaF25f2ECbcAf204ECADc8Db7B0db9DA845327);
  address constant public lLINK = address(0xeCfA53A8bdA4F0c4dd39c55CC8deF3757aCFDD07);
  address constant public lMANA = address(0xc89c4ed8f52Bb17314022f6c0dCB26210C905C97);
  address constant public lMKR = address(0xDa3d675d50fF6C555973C4f0424964e1F6A4e7D3);
  address constant public lREP = address(0xb8b513d9cf440C1b6f5C7142120d611C94fC220c);
  address constant public lSNX = address(0xE23d1142dE4E83C08bb048bcab54d50907390828);
  address constant public lWBTC = address(0x0133Aa47B6197D0BA090Bf2CD96626Eb71fFd13c);
  address constant public lZRX = address(0xA0F9D94f060836756FFC84Db4C78d097cA8C23E8);

  address[16] public oracles = [lETH, lDAI, lUSDC, lSUSD, lTUSD, lUSDT, lBAT, lKNC, lLEND, lLINK, lMANA, lMKR, lREP, lSNX, lWBTC, lZRX];

  address public constant dydx = address(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
  address public _user;

  function liquidate(address _victim) external nonReentrant {
    (address _collateral,) = getMaxCollateral(_victim);
    require(_collateral != address(0x0), "invalid");

    _user = _victim;
    (, uint256 _debt) = getMaxDebt(_user);
    uint256 amount = _debt.mul(200).div(100);

    Info[] memory infos = new Info[](1);
    ActionArgs[] memory args = new ActionArgs[](3);

    infos[0] = Info(address(this), 0);

    AssetAmount memory wamt = AssetAmount(false, AssetDenomination.Wei, AssetReference.Delta, amount);
    ActionArgs memory withdraw;
    withdraw.actionType = ActionType.Withdraw;
    withdraw.accountId = 0;
    withdraw.amount = wamt;
    withdraw.primaryMarketId = 2;
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
    deposit.primaryMarketId = 2;
    deposit.otherAddress = address(this);

    args[2] = deposit;

    IERC20(USDC).safeApprove(dydx, uint256(-1));
    DyDx(dydx).operate(infos, args);
    IERC20(USDC).safeApprove(dydx, 0);

    IERC20(USDC).safeTransfer(msg.sender, IERC20(USDC).balanceOf(address(this)));
  }

  function getIndex(address _reserve) public pure returns (uint256) {
    if (_reserve == ETH) {
      return 0;
    } else if (_reserve == DAI) {
      return 1;
    } else if (_reserve == USDC) {
      return 2;
    } else if (_reserve == SUSD) {
      return 3;
    } else if (_reserve == TUSD) {
      return 4;
    } else if (_reserve == USDT) {
      return 5;
    } else if (_reserve == BAT) {
      return 6;
    } else if (_reserve == KNC) {
      return 7;
    } else if (_reserve == LEND) {
      return 8;
    } else if (_reserve == LINK) {
      return 9;
    } else if (_reserve == MANA) {
      return 10;
    } else if (_reserve == MKR) {
      return 11;
    } else if (_reserve == REP) {
      return 12;
    } else if (_reserve == SNX) {
      return 13;
    } else if (_reserve == WBTC) {
      return 14;
    } else if (_reserve == ZRX) {
      return 15;
    }
  }

  function getMaxDebt(address _user) public view returns (address _reserve, uint256 _amount) {
    uint256 bTUSD = getDebt(TUSD, _user);
    uint256 bUSDT = getDebt(USDT, _user);
    uint256 bUSDC = getDebt(USDC, _user);
    uint256 bDAI = getDebt(DAI, _user);

    if (bTUSD > _amount) {
      _amount = bTUSD;
      _reserve = TUSD;
    }
    if (bUSDT.mul(1e12) > _amount) {
      _amount = bUSDT;
      _reserve = USDT;
    }
    if (bUSDC.mul(1e12) > _amount) {
      _amount = bUSDC;
      _reserve = USDC;
    }
    if (bDAI > _amount) {
      _amount = bDAI;
      _reserve = DAI;
    }
    return (_reserve, _amount);
  }

  function getDebt(address _reserve, address _user) public view returns (uint256) {
    (,uint256 debt,,,,,,,,) = Aave(aave).getUserReserveData(_reserve, _user);
    return debt;
  }

  function getMaxCollateral(address _user) public view returns (address _reserve, uint256 _amount) {
    // ETH-DAI, ETH-MKR, ETH-USDC, ETH-SNX, ETH-WBTC, ETH-BAT, ETH-LINK, ETH-KNC, ETH-sUSD
    uint256 _dai = getCollateral(DAI, _user, 1);
    uint256 _mkr = getCollateral(MKR, _user, 1);
    uint256 _usdc = getCollateral(USDC, _user, 1e12);
    uint256 _snx = getCollateral(SNX, _user, 1);
    uint256 _wbtc = getCollateral(WBTC, _user, 1e10);
    uint256 _bat = getCollateral(BAT, _user, 1);
    uint256 _link = getCollateral(LINK, _user, 1);
    uint256 _knc = getCollateral(KNC, _user, 1);
    uint256 _susd = getCollateral(SUSD, _user, 1);

    if (_dai > _amount) {
      _amount = _dai;
      _reserve = DAI;
    }
    if (_mkr > _amount) {
      _amount = _mkr;
      _reserve = MKR;
    }
    if (_usdc > _amount) {
      _amount = _usdc;
      _reserve = USDC;
    }
    if (_snx > _amount) {
      _amount = _snx;
      _reserve = SNX;
    }
    if (_wbtc > _amount) {
      _amount = _wbtc;
      _reserve = WBTC;
    }
    if (_bat > _amount) {
      _amount = _bat;
      _reserve = BAT;
    }
    if (_link > _amount) {
      _amount = _link;
      _reserve = LINK;
    }
    if (_knc > _amount) {
      _amount = _knc;
      _reserve = KNC;
    }
    if (_susd > _amount) {
      _amount = _susd;
      _reserve = SUSD;
    }
    return (_reserve, _amount);
  }

  function getCollateral(address _reserve, address _user, uint256 _dec) public view returns (uint256) {
    (uint256 _collateral, uint256 _debt,,,,,,,,) = Aave(aave).getUserReserveData(_reserve, _user);
    if (_debt >= _collateral) {
      return 0;
    } else {
      uint256 _diff = _collateral.sub(_debt);
      uint256 _price = getPrice(_reserve);
      return (_diff.mul(_dec)).mul(_price).div(1e18);
    }
  }
  function getCollateralToLiquidate(address _reserve, address _user) public view returns (uint256) {
    (uint256 _collateral,,,,,,,,,) = Aave(aave).getUserReserveData(_reserve, _user);
    return _collateral;
  }

  function getPrice(address _reserve) public view returns (uint256) {
    uint256 _index = getIndex(_reserve);
    if (_index == 0) {
      return 1e18;
    } else {
      return uint256(Oracle(oracles[_index]).latestAnswer());
    }
  }

  function callFunction(
      address sender,
      Info memory accountInfo,
      bytes memory data
  ) public {
    (address _reserve, uint256 _debt) = getMaxDebt(_user);
    (address _collateral,) = getMaxCollateral(_user);

    if (_reserve != USDC) {
      uint256 _sell = _debt.mul(105).div(100);
      IERC20(USDC).safeApprove(one, uint256(-1));
      OneSplit(one).goodSwap(USDC, _reserve, _sell, _debt, 1, 0);
      IERC20(_collateral).safeApprove(one, 0);
    }

    liquidate(_collateral, _reserve);

    if (_reserve != USDC) {
      IERC20(_reserve).safeApprove(one, uint256(-1));
      OneSplit(one).goodSwap(_reserve, USDC, IERC20(_reserve).balanceOf(address(this)), 1, 1, 0);
      IERC20(_reserve).safeApprove(one, 0);
    }
  }

  function liquidate(address _collateral, address _reserve) public {
    uint256 _to_liquidate = getCollateralToLiquidate(_collateral, _user);
    IERC20(_reserve).safeApprove(core, uint256(-1));
    Aave(aave).liquidationCall(_collateral, _reserve, _user, _to_liquidate, false);
    IERC20(_reserve).safeApprove(core, 0);
    uint256 _liquidated = IERC20(_collateral).balanceOf(address(this));
    require(_liquidated > 0, "failed");
    IERC20(_collateral).safeApprove(one, _liquidated);
    OneSplit(one).goodSwap(_collateral, _reserve, _liquidated, 1, 1, 0);
    IERC20(_collateral).safeApprove(one, 0);
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
