interface IIEther {
  // Invest ETH
  function invest() external payable;
  function calcPoolValueInETH() external view returns (uint);
  function getPricePerFullShare() external view returns (uint);
  // Redeem any invested tokens from the pool
  function redeem(uint256 _shares) external;
}
