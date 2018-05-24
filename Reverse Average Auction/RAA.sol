pragma solidity ^0.4.21;
// Add  source coordinate
contract RAAuction{
    address beneficiary;		    //Beneficiary
    uint auctionEnd;		        //Auction end time
    address public avgBidder;		//Address of average bidder
    uint public avgBid;			    //Closest Average bid amount
		        
    uint  bidSum=0; 

    uint count=0;
    address[] bidAddress;	        //Array of bidder addresses
    uint[] bidEther;		        //Array of bids
    mapping(address => uint) pendingReturns;
    bool ended;
    
    
    event AuctionEnded(address winner, uint amount);
    
    function RAAuction(uint _biddingTime, address _beneficiary)
    public
    {
        beneficiary=_beneficiary;
        auctionEnd= now +_biddingTime;
    }
    
    function bid()
    public payable{
        require(now<=auctionEnd);
        bidSum=bidSum+msg.value;
        bidAddress.push(msg.sender);
        bidEther.push(msg.value);
        pendingReturns[msg.sender]=msg.value;

        count=count+1;
    }
 
//Withdraw pending returns
   
    function withdraw() 
    public returns(bool)
    {
        uint amount=pendingReturns[msg.sender];
        if(amount>0)
        {
            pendingReturns[msg.sender]=0;
            if(!msg.sender.send(amount))
            {
                pendingReturns[msg.sender]=amount;
                return false;
            }
        }
        return true;
    }
 
//End of auction
   
    function endAuction()
    public{
	    uint minDiff=0;
    	uint temp=0;
    	uint  rawavgBid;
        require(now>=auctionEnd);
        require(!ended);
        
        ended=true;
        rawavgBid=bidSum/count;
        
        temp=bidEther[0]-rawavgBid;
        if(temp<0)
            temp=rawavgBid-bidEther[0];
        minDiff=temp;
        avgBid=bidEther[0];
        avgBidder=bidAddress[0];
        for (uint i=1; i<count; i++) 
        {

            temp=bidEther[i]-rawavgBid;
            if(temp<0)
                temp=rawavgBid-bidEther[i];
            if(minDiff>temp)
            {
                minDiff=temp;
                avgBid=bidEther[i];
                avgBidder=bidAddress[i];
            }
              
        }
        pendingReturns[avgBidder]=0;
        emit AuctionEnded(avgBidder,avgBid);
        
        beneficiary.transfer(avgBid);
    }
}
