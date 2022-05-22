pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./owner/Operator.sol";
import "./interfaces/ITaxable.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IERC20.sol";

/*
  
    BUKET.FINANCE - MULTI ALGORITHMIC TOKEN PEGGED 1 FTM VIA SEIGNIORAGE
    http://buket.finance
*/

contract TaxOfficeV2 is Operator {

    using SafeMath for uint256;
    address public buket = address(0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7);
    address public wftm = address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    address public uniRouter = address(0xF491e7B69E4244ad4002BC14e878a34207E38c29);

   // bool TAXFREE_LP_ENABLED = true;
    mapping(address => bool) public taxExclusionEnabled;

    function setTaxTiersTwap(uint8 _index, uint256 _value) public onlyOperator returns (bool) {
        return ITaxable(buket).setTaxTiersTwap(_index, _value);
    }

    function setTaxTiersRate(uint8 _index, uint256 _value) public onlyOperator returns (bool) {
        return ITaxable(buket).setTaxTiersRate(_index, _value);
    }

    function enableAutoCalculateTax() public onlyOperator {
        ITaxable(buket).enableAutoCalculateTax();
    }

    function disableAutoCalculateTax() public onlyOperator {
        ITaxable(buket).disableAutoCalculateTax();
    }

    function setTaxRate(uint256 _taxRate) public onlyOperator {
        ITaxable(buket).setTaxRate(_taxRate);
    }

    function setBurnThreshold(uint256 _burnThreshold) public onlyOperator {
        ITaxable(buket).setBurnThreshold(_burnThreshold);
    }

    function setTaxCollectorAddress(address _taxCollectorAddress) public onlyOperator {
        ITaxable(buket).setTaxCollectorAddress(_taxCollectorAddress);
    }

    function excludeAddressFromTax(address _address) external onlyOperator returns (bool) {
        return _excludeAddressFromTax(_address);
    }

    function _excludeAddressFromTax(address _address) private returns (bool) {
         if (!ITaxable(buket).isAddressExcluded(_address)) {
            return ITaxable(buket).excludeAddress(_address);
        }
    }

    function includeAddressInTax(address _address) external onlyOperator returns (bool) {
        return _includeAddressInTax(_address);
    }

    function _includeAddressInTax(address _address) private returns (bool) {
         if (ITaxable(buket).isAddressExcluded(_address)) {
            return ITaxable(buket).includeAddress(_address);
        }
    }

    function createLPTaxFreeNative(uint256 amtBuket) external payable returns (bool) {
    function taxRate() external view returns (uint256) {
        return ITaxable(buket).taxRate();
    }

    function addLiquidityTaxFree(
        address token,
        uint256 amtBuket,
        uint256 amtToken,
        uint256 amtBuketMin,
        uint256 amtTokenMin
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(amtBuket != 0 && amtToken != 0, "amounts can't be 0");
        _excludeAddressFromTax(msg.sender);

        IERC20(buket).transferFrom(msg.sender, address(this), amtBuket);
        IERC20(token).transferFrom(msg.sender, address(this), amtToken);
        _approveTokenIfNeeded(buket, uniRouter);
        _approveTokenIfNeeded(token, uniRouter);

        _includeAddressInTax(msg.sender);

        uint256 resultAmtBuket;
        uint256 resultAmtToken;
        uint256 liquidity;
        (resultAmtBuket, resultAmtToken, liquidity) = IUniswapV2Router(uniRouter).addLiquidity(
            buket,
            token,
            amtBuket,
            amtToken,
            amtBuketMin,
            amtTokenMin,
            msg.sender,
            block.timestamp
        );

        if(amtBuket.sub(resultAmtBuket) > 0) {
            IERC20(buket).transfer(msg.sender, amtBuket.sub(resultAmtBuket));
        }
        if(amtToken.sub(resultAmtToken) > 0) {
            IERC20(token).transfer(msg.sender, amtToken.sub(resultAmtToken));
        }
        return (resultAmtBuket, resultAmtToken, liquidity);
    }

    function addLiquidityETHTaxFree(
        uint256 amtBuket,
        uint256 amtBuketMin,
        uint256 amtFtmMin
    )
        external
        payable
        returns (
            uint256,
            uint256,
            uint256
        )
    {
     require(amtBuket != 0 && msg.value != 0, "amounts can't be 0");
     _excludeAddressFromTax(msg.sender);

        IERC20(buket).transferFrom(msg.sender, address(this), amtBuket);
        _approveTokenIfNeeded(buket, uniRouter);

        _includeAddressInTax(msg.sender);

        uint256 resultAmtBuket;
        uint256 resultAmtFtm;
        uint256 liquidity;
        (resultAmtBuket, resultAmtFtm, liquidity) = IUniswapV2Router(uniRouter).addLiquidityETH{value: msg.value}(
            buket,
            amtBuket,
            amtBuketMin,
            amtFtmMin,
            msg.sender,
            block.timestamp
        );

        if(amtBuket.sub(resultAmtBuket) > 0) {
            IERC20(buket).transfer(msg.sender, amtBuket.sub(resultAmtBuket));
        }
        return (resultAmtBuket, resultAmtFtm, liquidity);
    }

   function setTaxableBuektOracle(address _buketOracle) external onlyOperator {
        ITaxable(buket).setBuketOracle(_buketOracle);
    }
    function transferTaxOffice(address _newTaxOffice) external onlyOperator {
        ITaxable(buket).setTaxOffice(_newTaxOffice);
    }

    
    function taxFreeTransferFrom(
        address _sender,
        address _recipient,
        uint256 _amt
    ) external {
        require(taxExclusionEnabled[msg.sender], "Address not approved for tax free transfers");
        _excludeAddressFromTax(_sender);
        IERC20(buket).transferFrom(_sender, _recipient, _amt);
        _includeAddressInTax(_sender);
    }
    function setTaxExclusionForAddress(address _address, bool _excluded) external onlyOperator {
        taxExclusionEnabled[_address] = _excluded;
    }
    function _approveTokenIfNeeded(address _token, address _router) private {
        if (IERC20(_token).allowance(address(this), _router) == 0) {
            IERC20(_token).approve(_router, type(uint256).max);
        }
    }

}