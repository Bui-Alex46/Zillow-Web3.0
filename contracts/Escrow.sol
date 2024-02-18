//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}


contract Escrow {
    // State variables are saved on the blockchain
    // Lender will be saved in the smart contract on the chain
    // Public = variable is visible outside smart contract
    address public lender;
    address public inspector;
    address payable public seller;  //Person who receives the cryptocurrency
    address public nftAddress; 

     modifier onlyBuyer(uint256 _nftID){
        require(msg.sender == buyer[_nftID], "Only buyer can call this method");
        _;
     }
    
    modifier onlySeller(){
        require(msg.sender == seller, "Only seller can call this method");
        _;
    }

    modifier onlyInspector(){
        require(msg.sender == inspector, "Only inspector can call this method");
        _;
    }
   

    // Address of NFT => true or false
    mapping(uint256 => bool) public isListed;
    // Address of NFT => purchase Price
    mapping(uint256 => uint256) public purchasePrice;
    // Address of NFT => Escrow amount
    mapping(uint256 => uint256) public escrowAmount;
    // Address of NFT => address of buyer
    mapping(uint256 => address) public buyer;
    // Checks whether inspection passed or not
    mapping(uint256 => bool) public inspectionPassed;
    // NFTID => address of approval => true or false approval
    mapping(uint256 => mapping(address => bool)) public approval; 

    constructor(address _nftAddress, 
                address payable _seller, 
                address _inspector, 
                address _lender
    ){
        nftAddress = _nftAddress;
        seller = _seller;
        inspector = _inspector;
        lender = _lender;
    }
    // Take NFT out of users wallet and move it into Escrow
    function list(
        uint256 _nftID,
        address _buyer, 
        uint256 _purchasePrice, 
        uint256 _escrowAmount
        )public payable onlySeller{
        //transferFrom lets you move tokens from 1 wallet to another
        //Transfer NFT from seller to this contract
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftID);


        // Nft ID = 1. Check Escrow.js
        isListed[_nftID] = true;
        purchasePrice[_nftID] = _purchasePrice;
        escrowAmount[_nftID] = _escrowAmount;
        buyer[_nftID] = _buyer;
    }


    // Essentially a down payment from the buyer
    // Put Under Contract (only buyer - payable escrow)
    function depositEarnest(uint256 _nftID) public payable onlyBuyer(_nftID){
        require(msg.value >= escrowAmount[_nftID]);
    }

    // Update Inspection Status b/c it's boolean false by default
    // (Only inspector)
    function updateInspectionStatus(uint256 _nftID, bool _passed) 
    public onlyInspector {
        inspectionPassed[_nftID] = _passed;
        }
            
        
    function approveSale(uint256 _nftID) public {
        approval[_nftID][msg.sender] = true;
    }

    // Finalize sale
    //  -> Require inspectino status
    //  -> Require sale to be authorized
    //  -> require funds to be correct amount
    //  -> Transfer NFT to buyer
    //  -> Transfer funds to Seller
    function finalizeSale(uint256 _nftID) public {
        require(inspectionPassed[_nftID]);
        require(approval[_nftID][buyer[_nftID]]);
        require(approval[_nftID][seller]);
        require(approval[_nftID][lender]);
        require(address(this).balance >= purchasePrice[_nftID]);

        isListed[_nftID] = false;

        (bool success,) = payable(seller).call{value: address(this).balance}("");
        require(success);

        IERC721(nftAddress).transferFrom(address(this), buyer[_nftID], _nftID);
    }

    // Cancel Sale (handle earnest deposit)
    // if inspection status is not approved, then refund, otherwise send to seller
    function cancelSale(uint256 _nftID) public {
        if(inspectionPassed[_nftID] == false){
            payable(buyer[_nftID]).transfer(address(this).balance);
        }
        else{
            payable(seller).transfer(address(this).balance);
        }
    }
    

    // Function is called when contract reveives Ether.
    // It's automatically executed when Ether is sent directly
    // To the contract without specifying a function to call
    // External => function can only be called from outside the contract
    // Payable => function can receive Ether
    receive() external payable{}
    
    
    // Returning the balance of this smart contract address
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }


}
