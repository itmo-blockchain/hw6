import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";

import { expect } from "chai";
import { ethers } from "hardhat";

const PROVIDER_ADDRESS = "0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5"
const UNISWAP_V2_ROUTER_ADDRESS = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"

const WETH_ADDRESS = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
const DAI_ADDRESS = "0x6b175474e89094c44da98b954eedeac495271d0f"
const WBTC_ADDRESS = "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599"

const DEPLOYED_ORDER = [
    WETH_ADDRESS, DAI_ADDRESS, WBTC_ADDRESS, WETH_ADDRESS
]

const SWAP_EVENT_ABI = [
    "event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to)"
]
const SWAP_EVENT_TOPIC = new ethers.utils.Interface(SWAP_EVENT_ABI)

describe("BestLoserContract", function () {
    async function deployBestLoserFixture() {
        const [owner] = await ethers.getSigners();

        const BestLoserContract = await ethers.getContractFactory("BestLoserContract");
        const bestLoserContract = await BestLoserContract.deploy(
            PROVIDER_ADDRESS,
            UNISWAP_V2_ROUTER_ADDRESS, 
            DEPLOYED_ORDER
        ); 
        
        console.log("BestLoserContract deployed to:", bestLoserContract.address);

        const WETH = await ethers.getContractFactory("WETH9");
        const weth = WETH.attach(WETH_ADDRESS);

        weth.connect(owner).deposit({value: ethers.utils.parseEther("10")})

        return { bestLoserContract, weth, owner };
    }

    it("Should take flashloan and make tx", async function () {
        const {bestLoserContract, weth, owner} = await loadFixture(deployBestLoserFixture);

        weth.connect(owner).transfer(bestLoserContract.address, ethers.utils.parseEther("1"))

        const balanceBefore = await weth.balanceOf(bestLoserContract.address)
        console.log("Balance of BestLoserContract: " + balanceBefore.toString() + " WGwei \n")
        
        const tx = await bestLoserContract.flashBorrow(ethers.utils.parseEther("1"))
        
        const receipt = await tx.wait()
        
        receipt.logs.map(log => {
            try {
                return SWAP_EVENT_TOPIC.parseLog(log)
            } catch (e) {
                return undefined
            }
        }).filter(log => log !== undefined).forEach((log, index) => {
            let [fst, snd] = [DEPLOYED_ORDER[index], DEPLOYED_ORDER[index + 1]];
            
            if (fst > snd) {
                [fst, snd] = [snd, fst]
            }

            console.log(
                "Swap event:\n\tToken0: %s -> In: %s, Out: %s\n\tToken1: %s -> In: %s, Out: %s",
                fst,
                log?.args.amount0In.toString(),
                log?.args.amount0Out.toString(),
                snd,
                log?.args.amount1In.toString(),
                log?.args.amount1Out.toString()
            )
        })
        console.log()
        
        const balanceAfter = await weth.balanceOf(bestLoserContract.address)
        console.log("Balance of BestLoserContract: " + balanceAfter.toString() + " WGwei\n")

        if (balanceBefore > balanceAfter) {
            console.log("Profit: " + (balanceAfter.sub(balanceBefore)).toString() + " WGwei")
        } else {
            console.log("Loss: " + (balanceBefore.sub(balanceAfter)).toString() + " WGwei")
        }
    });
});