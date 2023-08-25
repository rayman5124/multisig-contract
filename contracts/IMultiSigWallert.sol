// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IMultiSigWallet {
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event AddOwner(address indexed owner);
    event RemoveOwner(address indexed owner);

    function numConfirmationsRequired() external view returns (uint);

    function isConfirmed(
        uint txIndex,
        address owner
    ) external view returns (bool);

    function isOwner(address) external view returns (bool);

    function owners(uint index) external view returns (address);

    function transactions(
        uint _txIndex
    )
        external
        view
        returns (
            uint txIndex,
            bool executed,
            uint8 numConfirmations,
            address to,
            uint value,
            bytes memory data
        );

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data,
        bool _confirm
    ) external;

    function getOwners() external view returns (address[] memory);

    function getTransactionCount() external view returns (uint);

    function confirmTransaction(uint _txIndex, bool _excute) external;

    function revokeConfirmation(uint _txIndex) external;

    function executeTransaction(uint _txIndex) external;

    function deleteTransaction(uint _txIndex) external;

    function addOwner(address owner) external;

    function removeOwner(address owner) external;

    function setNumConfirmationsRequired(uint8 required) external;
}