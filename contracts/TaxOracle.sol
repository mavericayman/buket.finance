pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
    BUKET.FINANCE - MULTI ALGORITHMIC TOKEN PEGGED 1 FTM VIA SEIGNIORAGE
    http://buket.finance
*/
contract BuketTaxOracle is Ownable {
    using SafeMath for uint256;

    IERC20 public buket;
    IERC20 public wftm;
    address public pair;

    constructor(
        address _buket,
        address _wftm,
        address _pair
    ) public {
        require(_buket != address(0), "buket address cannot be 0");
        require(_wftm != address(0), "wftm address cannot be 0");
        require(_pair != address(0), "pair address cannot be 0");
        buket = IERC20(_buket);
        wftm = IERC20(_wftm);
        pair = _pair;
    }

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut) {
        require(_token == address(buket), "token needs to be buket");
        uint256 buketBalance = buket.balanceOf(pair);
        uint256 wftmBalance = wftm.balanceOf(pair);
        return uint144(buketBalance.div(wftmBalance));
    }

    function setBuket(address _buket) external onlyOwner {
        require(_buket != address(0), "buket address cannot be 0");
        buket = IERC20(_buket);
    }

    function setWftm(address _wftm) external onlyOwner {
        require(_wftm != address(0), "wftm address cannot be 0");
        wftm = IERC20(_wftm);
    }

    function setPair(address _pair) external onlyOwner {
        require(_pair != address(0), "pair address cannot be 0");
        pair = _pair;
    }



}