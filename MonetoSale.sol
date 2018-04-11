pragma solidity ^0.4.11;

import "./Moneto.sol";

contract MonetoSale {
    Moneto public token;

    address public beneficiary;
    address public alfatokenteam;
    uint public alfatokenFee;
    
    uint public amountRaised;
    uint public tokenSold;
    
    uint public constant PRE_SALE_START = 1523952000; // 17 April 2018, 08:00:00 GMT
    uint public constant PRE_SALE_END = 1526543999; // 17 May 2018, 07:59:59 GMT
    uint public constant SALE_START = 1528617600; // 10 June 2018,08:00:00 GMT
    uint public constant SALE_END = 1531209599; // 10 July 2018, 07:59:59 GMT

    uint public constant PRE_SALE_MAX_CAP = 2531250 * 10**18;
    uint public constant SALE_MAX_CAP = 300312502 * 10**17;

    uint public constant SALE_MIN_CAP = 2500 ether;

    uint public constant PRE_SALE_PRICE = 1250;
    uint public constant SALE_PRICE = 1000;

    uint public constant PRE_SALE_MIN_BUY = 10 * 10**18;
    uint public constant SALE_MIN_BUY = 1 * 10**18;

    uint public constant PRE_SALE_1WEEK_BONUS = 35;
    uint public constant PRE_SALE_2WEEK_BONUS = 15;
    uint public constant PRE_SALE_3WEEK_BONUS = 5;
    uint public constant PRE_SALE_4WEEK_BONUS = 0;

    uint public constant SALE_1WEEK_BONUS = 10;
    uint public constant SALE_2WEEK_BONUS = 7;
    uint public constant SALE_3WEEK_BONUS = 5;
    uint public constant SALE_4WEEK_BONUS = 3;
    
    mapping (address => uint) public icoBuyers;

    Stages public stage;
    
    enum Stages {
        Deployed,
        Ready,
        Ended,
        Canceled
    }
    
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
        require(msg.sender == beneficiary);
        _;
    }

    function MonetoSale(address _beneficiary, address _alfatokenteam) public {
        beneficiary = _beneficiary;
        alfatokenteam = _alfatokenteam;
        alfatokenFee = 7 ether;

        stage = Stages.Deployed;
    }

    function setup(address _token) public isOwner atStage(Stages.Deployed) {
        require(_token != 0x0);
        token = Moneto(_token);

        stage = Stages.Ready;
    }

    function () payable public atStage(Stages.Ready) {
        require((now >= PRE_SALE_START && now <= PRE_SALE_END) || (now >= SALE_START && now <= SALE_END));

        uint amount = msg.value;
        amountRaised += amount;

        if (now >= SALE_START && now <= SALE_END) {
            assert(icoBuyers[msg.sender] + msg.value >= msg.value);
            icoBuyers[msg.sender] += amount;
        }
        
        uint tokenAmount = amount * getPrice();
        require(tokenAmount > getMinimumAmount());
        uint allTokens = tokenAmount + getBonus(tokenAmount);
        tokenSold += allTokens;

        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            require(tokenSold <= PRE_SALE_MAX_CAP);
        }
        if (now >= SALE_START && now <= SALE_END) {
            require(tokenSold <= SALE_MAX_CAP);
        }

        token.transfer(msg.sender, allTokens);
    }

    function transferEther(address _to, uint _amount) public isOwner {
        require(_amount <= this.balance - alfatokenFee);
        require(now < SALE_START || stage == Stages.Ended);
        
        _to.transfer(_amount);
    }

    function transferFee(address _to, uint _amount) public {
        require(msg.sender == alfatokenteam);
        require(_amount <= alfatokenFee);

        alfatokenFee -= _amount;
        _to.transfer(_amount);
    }

    function endSale(address _to) public isOwner {
        require(amountRaised >= SALE_MIN_CAP);

        token.transfer(_to, tokenSold*3/7);
        token.burn(token.balanceOf(address(this)));

        stage = Stages.Ended;
    }

    function cancelSale() public {
        require(amountRaised < SALE_MIN_CAP);
        require(now > SALE_END);

        stage = Stages.Canceled;
    }

    function takeEtherBack() public atStage(Stages.Canceled) returns (bool) {
        return proxyTakeEtherBack(msg.sender);
    }

    function proxyTakeEtherBack(address receiverAddress) public atStage(Stages.Canceled) returns (bool) {
        require(receiverAddress != 0x0);
        
        if (icoBuyers[receiverAddress] == 0) {
            return false;
        }

        uint amount = icoBuyers[receiverAddress];
        icoBuyers[receiverAddress] = 0;
        receiverAddress.transfer(amount);

        assert(icoBuyers[receiverAddress] == 0);
        return true;
    }

    function getBonus(uint amount) public view returns (uint) {
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            uint w = now - PRE_SALE_START;
            if (w <= 1 weeks) {
                return amount * PRE_SALE_1WEEK_BONUS/100;
            }
            if (w > 1 weeks && w <= 2 weeks) {
                return amount * PRE_SALE_2WEEK_BONUS/100;
            }
            if (w > 2 weeks && w <= 3 weeks) {
                return amount * PRE_SALE_3WEEK_BONUS/100;
            }
            if (w > 3 weeks && w <= 4 weeks) {
                return amount * PRE_SALE_4WEEK_BONUS/100;
            }
            return 0;
        }
        if (now >= SALE_START && now <= SALE_END) {
            uint w2 = now - SALE_START;
            if (w2 <= 1 weeks) {
                return amount * SALE_1WEEK_BONUS/100;
            }
            if (w2 > 1 weeks && w2 <= 2 weeks) {
                return amount * SALE_2WEEK_BONUS/100;
            }
            if (w2 > 2 weeks && w2 <= 3 weeks) {
                return amount * SALE_3WEEK_BONUS/100;
            }
            if (w2 > 3 weeks && w2 <= 4 weeks) {
                return amount * SALE_4WEEK_BONUS/100;
            }
            return 0;
        }
        return 0;
    }

    function getPrice() public view returns (uint) {
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            return PRE_SALE_PRICE;
        }
        if (now >= SALE_START && now <= SALE_START) {
            return SALE_PRICE;
        }
        return 0;
    }

    function getMinimumAmount() public view returns (uint) {
        if (now >= PRE_SALE_START && now <= PRE_SALE_END) {
            return PRE_SALE_MIN_BUY;
        }
        if (now >= SALE_START && now <= SALE_START) {
            return SALE_MIN_BUY;
        }
        return 0;
    }
}
