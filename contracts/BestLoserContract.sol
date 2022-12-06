// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { FlashLoanReceiverBase } from "@aave/protocol-v2/contracts/flashloan/base/FlashLoanReceiverBase.sol";
import { ILendingPoolAddressesProvider } from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract BestLoserContract is FlashLoanReceiverBase, Ownable {

    address public router;

    address[] public path;

    constructor(address _addressProvider, address _router, address[] memory _path) FlashLoanReceiverBase(ILendingPoolAddressesProvider(_addressProvider)) public {
        router = _router;

        require(_path.length >= 3, "Path must have at least 2 elements and last element must be equal to the first");
        require(_path[0] == _path[_path.length - 1], "Path must start and end with the same token");

        path = _path;
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Do your thing here.
        // The contract has the requested _amount of _reserve available as balance in the address of this contract.
        // The _fee of the _amount needs to be repaid.
        // The _params variable is arbitrary and can be used to pass additional variables to this function.
        // This contract must have the required approval to *pull* the _amount of _reserve.
        // The contract must have the required approval to *push* the _fee of _amount of _reserve.

        // Swap the _amount of _reserve for the token in the path



        SafeERC20.safeApprove(IERC20(assets[0]), router, amounts[0]);

        IUniswapV2Router02(router).swapExactTokensForTokens(amounts[0], 0, path, address(this), block.timestamp);

        // Approve the LendingPool contract allowance to *pull* the owed amount
        uint balance = IERC20(assets[0]).balanceOf(address(this));
        console.log("Approving LendingPool contract allowance to *pull* the owed amount");
        
        uint totalDebt = amounts[0] + premiums[0];

        console.log("Balance:    %s", balance);
        console.log("Total debt: %s", totalDebt);

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

        console.log("Calling flash loan");

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