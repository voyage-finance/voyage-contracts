contract Deposit {
    address _user;
    address _owner;

    constructor() public {
       _owner = msg.sender;
    }

    function initialize(address user) external {
        require(msg.sender == _owner, 'Deposit: FORBIDDEN');
        _user = user;
    }
}