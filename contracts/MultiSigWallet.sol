// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IMultiSigWallert.sol";

contract MultiSigWallet is IMultiSigWallet {
    struct Transaction {
        uint txIndex;
        bool executed;
        uint8 numConfirmations;
        address to;
        uint value;
        bytes data;
    }

    Transaction[] public transactions;
    uint public numConfirmationsRequired;
    mapping(uint => mapping(address => bool)) public isConfirmed; // mapping from tx index => owner => bool
    mapping(address => bool) public isOwner;
    address[] public owners;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier onlyWallet() {
        require(msg.sender == address(this), "not wallet");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint8 _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        uint len = _owners.length;
        for (uint i = 0; i < len;) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
            unchecked {
                i++;
            }
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data,
        bool _confirm
    ) external onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                txIndex: txIndex,
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);

        if(_confirm){
            confirmTransaction(txIndex, false);
        }
    }

    function confirmTransaction(
        uint _txIndex,
        bool _excute
    )
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        if(_excute) executeTransaction(_txIndex);

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(
        uint _txIndex
    ) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "not confirmed this tx yet");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function executeTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(address(this).balance >= transaction.value, "not enough balance");
        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "not enough confrimations"
        );

        transaction.executed = true;

        (bool success, bytes memory data) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        if(!success) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function deleteTransaction(uint _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        transactions[_txIndex].executed = true;
    }

    function addOwner(address owner) external onlyWallet {
        require(owner != address(0), "zero address");
        require(!isOwner[owner], "already owner");

        isOwner[owner] = true;
        owners.push(owner);

        emit AddOwner(owner);
    }

    function removeOwner(address owner) external onlyWallet {
        require(owner != address(0), "zero address");
        require(isOwner[owner], "not owner");
        require(
            numConfirmationsRequired <= owners.length - 1,
            "not enough owners"
        );

        isOwner[owner] = false;
        uint len = owners.length;
        for (uint i = 0; i < len;) {
            if (owners[i] == owner) {
                owners[i] = owners[len - 1];
                owners.pop();
                break;
            }
            unchecked {
                i++;
            }
        }

        emit RemoveOwner(owner);
    }

    function setNumConfirmationsRequired(uint8 required) external onlyWallet {
        require(required != numConfirmationsRequired, "same required number");
        require(
            required > 0 && required <= owners.length, 
            "invalid number of required confirmations"
        );
        numConfirmationsRequired = required;
    }

    function excuteBatch(
        address[] calldata toList,
        uint[] calldata valueList,
        bytes[] calldata dataList
    ) external onlyWallet {
        uint len = toList.length;
        require(len == valueList.length && len == dataList.length, "wrong array length");

        for (uint i = 0; i < len;) {
            (bool success, bytes memory result)= toList[i].call{value: valueList[i]}(dataList[i]);
            if(!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }
            unchecked {
                i++;
            }
        }
    }


    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() external view returns (uint) {
        return transactions.length;
    }

    function getTransactionsByPagination(
        uint offset,
        uint page // start from 0
    ) external view returns (Transaction[] memory) {
        require(offset > 0, "offset cannot be zero");
        uint startIndex = page * offset;
        require(startIndex < transactions.length, "out of range");
        if ((transactions.length - startIndex) < offset) {
            offset = transactions.length - startIndex;
        }

        Transaction[] memory transactions_ = new Transaction[](offset);
        for (uint i = 0; i < offset; i++) {
            transactions_[i] = transactions[page * offset + i];
        }
        return transactions_;
    }
}
