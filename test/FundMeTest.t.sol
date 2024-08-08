// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Test, console } from "forge-std/Test.sol";
import { FundMe } from "../src/FundMe.sol";
import { DeployFundMe } from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe s_fundMe;
    address FAKE_USER = makeAddr("Martin");
    uint256 constant SEND_VALUE = 1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        // s_fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMeContract = new DeployFundMe();
        s_fundMe = deployFundMeContract.run();
        vm.deal(FAKE_USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() view public {
        assertEq(s_fundMe.MINIMUM_USD(), 5e18); 
    }

    // Owner of the contract will not be us, instead of that it will be FundMeTest contract
    function testOwnerIsMsgSender() view public {
        assertEq(s_fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() view public {
        uint256 version = s_fundMe.getVersion();
        // console.log("VERSION", version);
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // We are expecting s_fundMe.fund() to fail

        s_fundMe.fund(); // With 0 msg.value
    }

    function testFundUpdatesFundedDataStructure() public funded {
        assertEq(s_fundMe.getAddressToAmountFunded(FAKE_USER), SEND_VALUE);
        assertEq(s_fundMe.getFunder(0), FAKE_USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(FAKE_USER);
        s_fundMe.withdraw();
    }

    function testWidthdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = s_fundMe.getOwner().balance;
        uint256 startingFundMeContractBalance = address(s_fundMe).balance;

        // Act
        vm.prank(s_fundMe.getOwner());
        s_fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = s_fundMe.getOwner().balance;
        uint256 endingFundMeContractBalance = address(s_fundMe).balance;

        assertEq(endingFundMeContractBalance, 0);
        assertEq(startingFundMeContractBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // Pranks + adds some ETH to the address
            hoax(address(i), STARTING_BALANCE);
            s_fundMe.fund{ value: SEND_VALUE }();
        }

        uint256 startingOwnerBalance = s_fundMe.getOwner().balance;
        uint256 startingFundMeContractBalance = address(s_fundMe).balance;

        // Act
        vm.startPrank(s_fundMe.getOwner());
        s_fundMe.withdraw();
        vm.stopPrank();

        // Assert
        uint256 endingOwnerBalance = s_fundMe.getOwner().balance;
        uint256 endingFundMeContractBalance = address(s_fundMe).balance;

        assert(endingFundMeContractBalance == 0);
        assert(startingOwnerBalance + startingFundMeContractBalance == endingOwnerBalance);
    }

    modifier funded() {
        vm.prank(FAKE_USER); // The next transaction will be sent by FAKE_USER
        s_fundMe.fund{ value: SEND_VALUE }();
        _;
    }

}