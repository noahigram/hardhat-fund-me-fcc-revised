//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// need interface to work with
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

//Get funds from users
//Withdraw funds
// Set a minimum funding value in USD

error FundMe__NotOwner();

/** @title A contract for crowd funding
 * @author Noah Igram
 * @notice This contract was made to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type declarations
    using PriceConverter for uint256;

    // State variables
    mapping(address => uint256) private s_addressToAmountFunded;
    uint256 public constant MINIMUM_USD = 50 * 10**18;
    address[] private s_funders;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
        //uses less gas than require
        //this line runs tells the function to execute the original code of the function
    }

    // Functions in this order: constructor, receive, fallback, external, public, internal, private, view / pure

    // Constructor gets called immediately when the contract is deployed
    constructor(address priceFeedAddress) {
        s_priceFeed = AggregatorV3Interface(priceFeedAddress); // sets priceFeed to AggregatorV3interface corresponding to priceFeedAdress
        i_owner = msg.sender;
    }

    function fund() public payable {
        // Want to be able to set a minimum funding value
        // How do we send ETH to this contract? Contracts can hold tokens
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        ); //requires the amount to be greater than 1e18 (measured in Wei)
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);

        // What is reverting?
        // Undoes any action before, and send remaining gas back
    }

    function withdraw() public payable onlyOwner {
        //for loop
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);

        //actually withdraw the funds

        //transfer- capped at 2300 gas, automatically reverts if gas is over limit
        // msg.sender is an address
        // payable(msg.sender) is a payable address
        //payable(msg.sender).transfer(address(this).balance);

        //send- capped at 2300 gas, doesn't automaticaly revert
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function cheaperWithdraw() public onlyOwner {
        // mappings can't be in memory, sorry!
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getAddressToAmountFunded(address fundingAddress)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
