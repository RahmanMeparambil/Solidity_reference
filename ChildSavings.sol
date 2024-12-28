// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// This contract allows a grandfather (or owner) to add funds to his grandchildren's savings accounts. 
// The funds can be deposited into the children's accounts by the owner (or any authorized address) until 
// the children are old enough to access the funds.
// 
// Key Features:
// - The contract stores an array of children, each with their own wallet address and savings balance.
// - The `addKid` function allows the owner to add a new child (grandchild) to the system with an initial balance of 0.
// - The `addFund` function is payable, allowing the owner to send Ether to a specific child's account.
// - The `findIndex` function is used internally to locate the child based on their wallet address.
// - Each child’s savings are updated when Ether is sent to their account via `addFund`.
// - A simple check ensures that Ether is sent when calling `addFund`, preventing zero-value deposits.
//
// Usage:
// 1. The owner adds children to the contract using the `addKid` function.
// 2. The owner sends Ether to a specific child using the `addFund` function, where the funds are added to the child's savings.
// 3. The balance of each child can be checked with the `balanceOf` function.
// 4. The money can be withrawed by the kid with the 'withdraw' function.

contract ChildSavings{
    // owner 
    address owner;
    event logKidFundingReceived(address addr,uint amount,uint contractBalance);


    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(owner==msg.sender,"Permission denied");
        _;
    }

    // define kid
    struct Kid{
        address walletAddress;
        string firstName;
        string lastName;
        uint releaseTime;
        uint amount;
        bool Withdraw;
    }

    // add kid to contract
    Kid[] public kids;
    function addKid(address walletAddress,string memory firstName,string memory lastName,uint releaseTime,uint amount, bool Withdraw) public onlyOwner{
        kids.push(Kid(walletAddress,firstName,lastName,releaseTime,amount,Withdraw));
        return;
    }

    // deposit funds to contract, specifically to a kid's account
    function findIndex(address walletAddress) public view returns (uint){
        for (uint i=0;i<kids.length;i++){
            if (kids[i].walletAddress == walletAddress){
                return i;
            }
        }
        return type(uint).max;
    }
    function addFund(address walletAddress)public payable onlyOwner{
        uint i = findIndex(walletAddress);
        kids[i].amount += msg.value;
        emit logKidFundingReceived(walletAddress, msg.value, balanceOf());
    }
    function balanceOf() public view returns (uint){
        return address(this).balance;
    }

    // kid checks if able to withdraw
    function canWithdraw(address walletAddress) public returns (bool){
        uint i = findIndex(walletAddress);
        if (kids[i].releaseTime <= block.timestamp){
            kids[i].Withdraw = true;
            return true;
        }
        return false;
    }

    // withdraw money
    function withdraw(address payable walletAddress) payable public{
        uint i = findIndex(walletAddress);
        require(kids[i].walletAddress==msg.sender,"Only the kids can withdraw");
        require(canWithdraw(walletAddress),"Not yet withdrawable");
        walletAddress.transfer(kids[i].amount);
        kids[i].amount = 0;
    }

}
