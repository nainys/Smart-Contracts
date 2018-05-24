pragma solidity ^0.4.0;
contract Bank{
    
    struct account{
        address addr1;
        address addr2;
        uint balance;
        uint fd_amount;
        uint fd_time;
        bool isJoint;
    }
    

    mapping (address => account) private customers;
    mapping (address => bool) private deactive;
    mapping (address => bool) private active;
    
    uint private minbal = 1 ether; // minimum balance
    uint private tlimit = 3 ether; // transfer limit
    uint private wlimit = 5 ether; // withdraw limit
    uint private dlimit = 10 ether; // deposit limit
    
    
    function request_activation() public
    {
        active[msg.sender] = true;
    }
    
    function account_registration() public payable 
    {
            require(active[msg.sender]);
            require(customers[msg.sender].addr1 == address(0));
            customers[msg.sender].addr1 = msg.sender;
            customers[msg.sender].addr2 = address(0);
            customers[msg.sender].balance = msg.value;
            customers[msg.sender].isJoint = false;
            
            require(customers[msg.sender].balance > minbal && customers[msg.sender].balance <= dlimit);
      
    }
    
    function joint_acc_registration(address addr1,address addr2) public payable
    {
            require(addr1 == msg.sender || addr2 == msg.sender);
            require(active[addr1] && active[addr2]);
            require(customers[msg.sender].addr1 == address(0) && customers[msg.sender].addr2 == address(0));
            customers[addr1].addr1 = addr1;
            customers[addr1].addr2 = addr2;
            customers[addr1].balance = msg.value;
            customers[addr1].isJoint = true;
            customers[addr2] = customers[addr1];
            
            require(customers[addr1].balance >= minbal && customers[addr2].balance>=minbal);
            require(customers[addr1].balance <= dlimit && customers[addr2].balance <= dlimit);

    }
    
    function request_deactivation() public{
        deactive[msg.sender] = true;
    }
    
    function deactivate_account() public
    {
            require(deactive[msg.sender] && !customers[msg.sender].isJoint);
            //transfer remaining balance
            msg.sender.transfer(customers[msg.sender].balance);
            delete customers[msg.sender];
    }
    
    function deactivate_joint_account(address addr1,address addr2) public
    {
            require(addr1 == msg.sender || addr2 == msg.sender);
            require(deactive[addr1] && deactive[addr2] && customers[msg.sender].isJoint);
            //transfer remaining balance
            msg.sender.transfer(customers[msg.sender].balance);
            delete customers[addr1];
            delete customers[addr2];
    }
    
    function deposit() payable public returns (uint)
    {
        // Check for registered customer
        require(customers[msg.sender].addr1 != address(0));
        
        // Check for deposit limit
        require(msg.value <= dlimit);
        
        if(customers[msg.sender].isJoint)
        {
            address addr1 = customers[msg.sender].addr1;
            address addr2 = customers[msg.sender].addr2;
            
            //Checking overflow
            require((customers[addr1].balance + msg.value) >= customers[addr1].balance);
            require((customers[addr2].balance + msg.value) >= customers[addr2].balance);
            
            customers[addr1].balance += msg.value;
            customers[addr1].balance += msg.value;
        }
       
       else{
           
           // Checking overflow
           require((customers[msg.sender].balance + msg.value) >= customers[msg.sender].balance);
           customers[msg.sender].balance += msg.value;
       }
       return customers[msg.sender].balance;
    }
    
    function check_bal() public returns(uint)  {
        return customers[msg.sender].balance;
    }
    
    
    function withdraw(uint wamount) public returns (uint)
    {
        // Check for registered customer
        require(customers[msg.sender].addr1 != address(0));
        // Checking withdrawal limit
        require(wamount<=wlimit);
        //Checking minimum balance limit
        require(customers[msg.sender].balance>= (wamount+minbal));
        if(customers[msg.sender].isJoint) {
            address addr1 = customers[msg.sender].addr1;
            address addr2 = customers[msg.sender].addr2;
            customers[addr1].balance -= wamount;
            customers[addr2].balance -= wamount;

        }
        else{
            customers[msg.sender].balance -= wamount;
        }
        msg.sender.transfer(wamount);
        return customers[msg.sender].balance;
    }
    
    function transfer_funds(address to, uint tamount) public returns(bool)
    {
        // Check for registered customer
        require(customers[to].addr1 != address(0));
        //Checking transfer limit
        require(tamount <= tlimit);
        //Checking minimum balance limit
        require(customers[msg.sender].balance >= (tamount+minbal));
        
        //overflow check
        if(customers[to].balance + tamount < customers[to].balance)
        {
            revert();
        }
        if(customers[msg.sender].isJoint)
        {
            address adr1 = customers[msg.sender].addr1;
            address adr2 = customers[msg.sender].addr2;
            
            customers[adr1].balance -= tamount;
            customers[adr2].balance -= tamount;

            
        }
        else{
            customers[msg.sender].balance -= tamount;
        }
        if(customers[to].isJoint)
        {
            address addr1 = customers[to].addr1;
            address addr2 = customers[to].addr2;
            
            customers[addr1].balance += tamount;
            customers[addr2].balance += tamount;

        }
        else{
             customers[to].balance += tamount;
        }
        return true;
    }
    
    function deposit_fd(uint time) payable public returns(uint)
    {
        require(customers[msg.sender].addr1 != address(0));
        if(customers[msg.sender].isJoint) {
            
            address addr1 = customers[msg.sender].addr1;
            address addr2 = customers[msg.sender].addr2;
            
            customers[addr1].fd_amount += msg.value;
            customers[addr2].fd_amount += msg.value;
            customers[addr1].fd_time = now+time;
            customers[addr2].fd_time = customers[addr1].fd_time;
        }
       
       else{

           customers[msg.sender].fd_amount += msg.value;
           customers[msg.sender].fd_time = now+time;
       }
       
       return customers[msg.sender].fd_amount;
    }
    
    function withdraw_fd() public returns(uint)
    {
        require(customers[msg.sender].addr1 != address(0));
        require(customers[msg.sender].fd_amount >0);
        
        //Fd cannot be broken before time
        require(now > customers[msg.sender].fd_time);
        
         if(customers[msg.sender].isJoint)
        {
            address addr1 = customers[msg.sender].addr1;
            address addr2 = customers[msg.sender].addr2;
            customers[addr1].fd_amount = 0;
            customers[addr2].fd_amount = 0;

        }
        else
        {
            customers[msg.sender].fd_amount = 0;
        }
        msg.sender.transfer(customers[msg.sender].fd_amount);
        return customers[msg.sender].fd_amount;
    }
    
    function() payable public{
        revert();
    }
    
}
