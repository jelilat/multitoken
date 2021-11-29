// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Creator is ERC1155, Ownable {

    AggregatorV3Interface internal priceFeed;

    uint public totalContributions;
    uint public totalContributors;
    uint public totalTokens;
    uint reward;
    uint256 ethUSD;

    struct CreatorData {
        address payable creatorAddress;
        uint256 valuation;
        uint256 totalContribution;
        bool isMinted;
        uint contributorsCount;
        uint id;
        uint256 balance;
        uint256 maximumTokenSupply;
    }
     
    mapping(string => CreatorData) creators;

    event raiseData(address indexed _creator, uint256 _valuation, uint256 _totalContribution, bool _isMinted, uint _contributorsCount, uint _id, uint256 _balance);
    event contributionData(string _token, address indexed _contributor, uint256 _reward);
    event contributionWithdrawalData(string _token, address _creator, uint256 _amount);
    event withdrawProfit(uint _value, address indexed _destination);

    constructor() ERC1155("https://creator.example/api/item/{id}.json") {
        priceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
    }

    receive() external payable {
        //creators[msg.sender] = msg.sender;
    }

    function getLatestPrice() private view returns (uint256) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function raise(string memory tokenSymbol, uint256 _valuation, uint256 tokenSupply) payable public {
        require(creators[tokenSymbol].isMinted == false, "Token already created");

        ethUSD = (msg.value * getLatestPrice())/10**18;

        creators[tokenSymbol].creatorAddress = payable(msg.sender);
        creators[tokenSymbol].valuation = _valuation;
        creators[tokenSymbol].totalContribution = ethUSD;
        creators[tokenSymbol].isMinted = true;
        creators[tokenSymbol].id = totalTokens;
        creators[tokenSymbol].maximumTokenSupply = tokenSupply;
        
        if (msg.value != 0) {
            creators[tokenSymbol].contributorsCount += 1;
            totalContributors += 1;
            totalContributions += ethUSD;
            creators[tokenSymbol].valuation += ethUSD;
            creators[tokenSymbol].balance += ethUSD;
            
        }
        totalTokens += 1;

        if (creators[tokenSymbol].valuation == 0) {
                reward = (ethUSD * 100)/10**8;
                _mint(msg.sender, creators[tokenSymbol].id, reward, "");
            } else {
                reward = ((ethUSD * ethUSD * 100)/creators[tokenSymbol].valuation)/10**8;
                _mint(msg.sender, creators[tokenSymbol].id, reward, "");
            }

        emit raiseData(msg.sender, _valuation, ethUSD, true, creators[tokenSymbol].contributorsCount, creators[tokenSymbol].id, creators[tokenSymbol].balance);
    }

    function getCreator(string memory tokenSymbol) public view returns (address) {
        return creators[tokenSymbol].creatorAddress;
    }

    function getValuation(string memory tokenSymbol) public view returns (uint256) {
        return creators[tokenSymbol].valuation;
    }

    function getTokenContributions(string memory tokenSymbol) public view returns (uint256) {
        return creators[tokenSymbol].totalContribution;
    }

    function getTokenContributorsCount(string memory tokenSymbol) public view returns (uint) {
        return creators[tokenSymbol].contributorsCount;
    }

    function uintToString(uint v) private pure returns (string memory str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - 1 - j];
        }
        str = string(s);
        return str;
    }

    function getMaximumTokenSupply(string memory tokenSymbol) public view returns (string memory) {
        string memory maxSupply;

        if (creators[tokenSymbol].maximumTokenSupply == 0) {
            maxSupply = "Unlimited";
            return maxSupply;
        } else {
            maxSupply = uintToString(creators[tokenSymbol].maximumTokenSupply);
            return maxSupply;
        }
    }

    function contribute(string memory tokenSymbol) public payable {
        require(creators[tokenSymbol].isMinted == true, "Token not created");

        ethUSD = (msg.value * getLatestPrice())/10**18;

        creators[tokenSymbol].totalContribution += ethUSD;
        creators[tokenSymbol].valuation += ethUSD;
        creators[tokenSymbol].balance += ethUSD;
        totalContributions += ethUSD;

        if (msg.value != 0) {
            creators[tokenSymbol].contributorsCount += 1;
            totalContributors += 1;

            if (creators[tokenSymbol].valuation == 0) {
                reward = (ethUSD * 100)/10**8;
                require(reward <= creators[tokenSymbol].maximumTokenSupply, "Token supply exceeded");
                _mint(msg.sender, creators[tokenSymbol].id, reward, "");
            } else {
                reward = ((ethUSD * ethUSD * 100)/creators[tokenSymbol].valuation)/10**8;
                require(reward <= creators[tokenSymbol].maximumTokenSupply, "Token supply exceeded");
                _mint(msg.sender, creators[tokenSymbol].id, reward, "");
            }
            
        }
        emit contributionData(tokenSymbol, msg.sender, reward);
    }

    function withdrawContribution(uint256 _amount, string memory _tokenSymbol) public payable{

        ethUSD = (_amount * getLatestPrice())/10**18;
        
        require(creators[_tokenSymbol].isMinted == true, "Token not created");
        require(creators[_tokenSymbol].creatorAddress == msg.sender, "Only creator can withdraw contributions");
        require(creators[_tokenSymbol].balance >= (ethUSD/10**7)/9, "Not enough tokens");

        creators[_tokenSymbol].balance -= _amount;
        (creators[_tokenSymbol].creatorAddress).transfer(_amount);
        emit contributionWithdrawalData(_tokenSymbol, msg.sender, _amount);
    }

    function takeProfit(uint _amount, address payable _destAddr) public onlyOwner {
        require(msg.sender == _destAddr, "Only owner can withdraw funds"); 
        require(_amount <= totalContributions/100, "Amount exceeds profit");
        
        _destAddr.transfer(_amount);
        emit withdrawProfit(_amount, _destAddr);
    }
}

