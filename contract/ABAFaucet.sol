// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title ABACoinFaucet
/// @author Ahmet Buğra Aydın
/// @notice This contract aim is to mint and request ABA Coin's from faucet.

contract ABAFaucet is ERC20, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private userCount;
    
    uint256 public constant lockTime = 10 seconds;
    uint256 public constant withdrawalAmount = 2 * 10**15;

    struct User {
        uint256 userId;
        address userAddress;
        uint256 requestTime;
        uint256 donated;
    }

    mapping(address => User) public users;

    event Donate(address indexed from, uint256 indexed amount);
    event Request(address indexed to, uint256 indexed amount);

    constructor() ERC20("ABA Coin", "ABA") payable {
        // Mint 300 ABA Coins for contract  
        mint(address(this), 300 * 10 ** 18);
    }

    modifier nonZeroAddress() {
        require(msg.sender != address(0), "address can not be zero");
        _;
    }

    modifier validBalance() {
        require(balanceOf(address(this)) > withdrawalAmount, "main balance is low");
        _;
    }

    /// @dev Donate tokens to faucet
    receive() external payable {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @dev Log users interacts with the contract
    function logUser() public {
        User memory user = User({
            userId: userCount.current(),
            userAddress: msg.sender,
            requestTime: 0,
            donated: 0
        });

        users[msg.sender] = user;
        userCount.increment();
    }

    /// @dev Request tokens from faucet
    function requestTokens() public  nonZeroAddress validBalance {
        if (
            users[msg.sender].requestTime != 0
            && users[msg.sender].requestTime + lockTime > block.timestamp
        )
        { revert("can only request once in locktime"); }

        if(users[msg.sender].userId == 0) {
            logUser();
        }

        users[msg.sender].requestTime = block.timestamp;
        _transfer(address(this), msg.sender, withdrawalAmount);
        emit Request(msg.sender, withdrawalAmount);
    }

    /// @dev Donate to faucet balance
    function donate(uint _amount) public payable {
        if (users[msg.sender].userId == 0) {
            logUser();
        }

        _transfer(msg.sender, address(this), _amount);
        users[msg.sender].donated += _amount;
        emit Donate(msg.sender, _amount);
    }

    /// @dev Get faucet balance
    function getBalance() public view returns(uint256) {
        return balanceOf(address(this));
    }

    /// @dev Widthdraw all faucet balance
    function widthdraw() public onlyOwner {
        _transfer(address(this), msg.sender, balanceOf(address(this)));
    }

}
