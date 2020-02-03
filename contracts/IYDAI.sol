pragma solidity ^0.5.0;

interface IyDAI {

  function recommend() external view returns (uint256);

  function supplyDydx(uint256 amount) external returns(uint);

  function balance() external view returns (uint256);

  function getAave() external view returns (address);
  function getAaveCore() external view returns (address);

  function approveToken() external;

  function balanceDydx() external view returns (uint256);
  function balanceCompound() external view returns (uint256);
  function balanceCompoundInToken() external view returns (uint256);
  function balanceFulcrumInToken() external view returns (uint256);
  function balanceFulcrum() external view returns (uint256);
  function balanceAave() external view returns (uint256);

  function rebalance() external;

  function supplyAave(uint amount) external;
  function supplyFulcrum(uint amount) external;
  function supplyCompound(uint amount) external;

  // Invest ETH
  function invest(uint256 _amount) external;

  // Invest self eth from external profits
  function investSelf() external;

  function calcPoolValueInToken() external view returns (uint256);

  function getPricePerFullShare() external view returns (uint256);

  // Redeem any invested tokens from the pool
  function redeem(uint256 _shares) external;
}
