
interface IyCRV {
  function balanceCompound() external view returns (uint256);
  function supplyCompound(uint amount) external;
  function invest(uint256 _amount) external;

  function crvapr() external view returns (uint256);

  function calcPoolValueInToken() external view returns (uint);

  function getPricePerFullShare() external view returns (uint);

  // Redeem any invested tokens from the pool
  function redeem(uint256 _shares) external;
}
