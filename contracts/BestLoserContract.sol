// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import { FlashLoanReceiverBase } from "@aave/protocol-v2/contracts/flashloan/base/FlashLoanReceiverBase.sol";
import { ILendingPoolAddressesProvider } from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

contract BestLoserContract is FlashLoanReceiverBase, Ownable {

    address public router;
    address[] public path;

    constructor(address _addressProvider, address _router, address[] memory _path) FlashLoanReceiverBase(ILendingPoolAddressesProvider(_addressProvider)) public {
        require(_path.length >= 3, "Path must have at least 3 elements");
        require(_path[0] == _path[_path.length - 1], "Path must start and end with the same token");

        router = _router;
        path = _path;
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address,
        bytes calldata
    ) external override returns (bool) {

        require(assets.length == 1 && amounts.length == 1 && premiums.length == 1, "Invalid arrays length");
        require(assets[0] == path[0], "Invalid asset");

        SafeERC20.safeApprove(IERC20(assets[0]), router, amounts[0]);

        IUniswapV2Router02(router).swapExactTokensForTokens(amounts[0], 0, path, address(this), block.timestamp);
        
        uint totalDebt = amounts[0] + premiums[0];
        SafeERC20.safeApprove(IERC20(assets[0]), address(LENDING_POOL), totalDebt);

        return true;
    }

    // This function must be called when you want to flash borrow _amount of path[0]
    function flashBorrow(uint256 _amount) external onlyOwner {
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = path[0];

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        LENDING_POOL.flashLoan(receiverAddress, assets, amounts, modes, address(0), "", 0);
    }

    function withdraw() external onlyOwner {
        IERC20(path[0]).transfer(msg.sender, IERC20(path[0]).balanceOf(address(this)));
    }

    function withdrawToken(address _token) external onlyOwner {
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    function withdrawEth() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setPath(address[] memory _path) external onlyOwner {
        require(_path.length >= 3, "Path must have at least 2 elements and last element must be equal to the first");
        require(_path[0] == _path[_path.length - 1], "Path must start and end with the same token");

        path = _path;
    }
}