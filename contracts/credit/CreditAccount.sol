contract Deposit {
    address _user;
    address _owner;

    function initialize(address user) external {
        require(msg.sender == _owner, 'Deposit: FORBIDDEN');
        _user = user;
        _owner = msg.sender;
    }
}