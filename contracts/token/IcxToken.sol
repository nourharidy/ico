pragma solidity ^0.4.11;

import "./erc20.sol";
import "./Lockable.sol";
import '../util/SafeMath.sol';
import "./oldToken.sol";

// ICON ICX Token
/// @author DongOk Ryu - <pop@theloop.co.kr>, bug fix & improvements by Nour Haridy - <nour@lamarkaz.com>
contract IcxToken is ERC20, Lockable {
    using SafeMath for uint;

    mapping( address => uint ) _balances;
    mapping( address => mapping( address => uint ) ) _approvals;
    uint _supply;
    address public walletAddress;
    oldTokenInterface icxInterface;
    bool counterSpammer;

    event TokenBurned(address burnAddress, uint amountOfTokens);
    event TokenTransfer(bool value);
    event CounterSpam(bool value);

    modifier onlyFromWallet {
        // require(msg.sender != walletAddress); Fixed bug: https://github.com/icon-foundation/ico/issues/3
        require(msg.sender == walletAddress);
        _;
    }

    modifier checkCounterSpam {
      if(counterSpammer) {
        icxInterface.enableTokenTransfer();
      }
      _;
    }

    function IcxToken( uint initial_balance, address wallet, address oldIcx) {
        require(wallet != 0);
        require(initial_balance != 0);
        _balances[msg.sender] = initial_balance;
        _supply = initial_balance;
        walletAddress = wallet;
        icxInterface = oldTokenInterface(oldIcx);
    }

    function totalSupply() constant returns (uint supply) {
        return _supply;
    }

    function balanceOf( address who ) constant returns (uint value) {
        return _balances[who];
    }

    function allowance(address owner, address spender) constant returns (uint _allowance) {
        return _approvals[owner][spender];
    }

    function transfer( address to, uint value)
    isTokenTransfer
    checkLock
    checkCounterSpam
    returns (bool success) {

        require( _balances[msg.sender] >= value );

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        Transfer( msg.sender, to, value );
        return true;
    }

    function transferFrom( address from, address to, uint value)
    isTokenTransfer
    checkLock
    checkCounterSpam
    returns (bool success) {
        // if you don't have enough balance, throw
        require( _balances[from] >= value );
        // if you don't have approval, throw
        require( _approvals[from][msg.sender] >= value );
        // transfer and return true
        _approvals[from][msg.sender] = _approvals[from][msg.sender].sub(value);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        Transfer( from, to, value );
        return true;
    }

    function approve(address spender, uint value)
    isTokenTransfer
    checkLock
    checkCounterSpam
    returns (bool success) {
        _approvals[msg.sender][spender] = value;
        Approval( msg.sender, spender, value );
        return true;
    }

    function burnTokens(uint tokensAmount)
    isTokenTransfer
    checkCounterSpam
    external
    {
        require( _balances[msg.sender] >= tokensAmount );

        _balances[msg.sender] = _balances[msg.sender].sub(tokensAmount);
        _supply = _supply.sub(tokensAmount);
        TokenBurned(msg.sender, tokensAmount);

    }

    function triggerTransfer(bool value)
    external
    onlyFromWallet {
        tokenTransfer = value;
        TokenTransfer(value);
    }

    // Token recovery from old contract to new contract. Fix by Nour Haridy <nour@lamarkaz.com>
    function recover()
    isTokenTransfer
    checkLock
    external
    {
      uint balance = icxInterface.allowance(msg.sender, address(this));
      require(balance > 0);
      icxInterface.enableTokenTransfer();
      icxInterface.transferFrom(msg.sender, address(this), balance);
      icxInterface.burnTokens(balance);
      _balances[msg.sender] = _balances[msg.sender].add(balance);
      Transfer(address(0), msg.sender, balance);
    }

    function triggerCounterSpam(bool value)
    external
    onlyFromWallet
    {
      counterSpammer = value;
      CounterSpam(value);
    }

}
