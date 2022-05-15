// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";


contract project {

    //participant array
    address [] participants;
    //fixed expenses
    uint fixedExpenses;
    //timerForFixedExpenses
    uint256  timerForFixedExpenses;
    //participant fee 
    uint participantFee;
    //16 byte, 32 digit car id
    uint64  carID;

    //timer for pay Profit to participants
    uint256 payDividendTimer;

    //project owner
    address  private  projectOwner;
    //project balances
    //i use address(this).balance for project balance, if you check the balance, you can call getBalance function
    uint balance;  

    //car dealer address
    address  carDealer;
    //Car dealer address TODO:delete
    uint256 carDealerBalance;
    //flag for assign car dealer
    bool carDealerIsAssigned;
    //timer for car expenese
    uint256 carExpensesTimer;
    //address of car driver
    address  carDriver;
    //car driver balance TODO:delete
    uint256 carDriverBalance;
    //expected salary from driver
    uint256 carDriverExpectedSalary;
    //timer for driver's salary
    uint256 carDriverMontly;

    //proposal struct
    struct proposalCarStruct{
        uint64 id;
        uint price;
        uint validTime;
        uint approvedState;
    }
    //driver struct
    struct driverStruct{
        address driverAddress;
        uint  salary;
        uint approvedState;
    }

    //object of the struct to buy car
    proposalCarStruct proposedCar;
    //object of the struct to sell car
    proposalCarStruct proposedPurchase;
    //object of the struct store proposed driver infos.
    driverStruct proposedDriver;

    
    constructor(address carDealerAddress){
        console.log("In Constructor");
        //assign owner of the project
        projectOwner = msg.sender;
        //initialize the time
        timerForFixedExpenses = block.timestamp;

        participantFee = 100 ether;
        //participantFee = 1 ether;

        fixedExpenses = 10 ether;
        //fixedExpenses = 1 ether;
        //initialize balance
        balance = 0;
        
        //initialize proposed car struct
        proposedCar.id=0;
        proposedCar.price=0;
        proposedCar.validTime=0;
        proposedCar.approvedState=0;

        //initialize proposed purchase struct
        proposedPurchase.id=0;
        proposedPurchase.price=0;
        proposedPurchase.validTime=0;
        proposedPurchase.approvedState=0;
        //carDealer address assignment
        carDealer= carDealerAddress;
        //initialize bool checker
        carDealerIsAssigned=true;
        //future ten years
        carExpensesTimer=1968145216;
        payDividendTimer=0;

        //not used
        carDealerBalance=0;
        //car id 4 byte
        carID=0;
        //try null address
        //console.log(address(0));
        //initalize proposed driver
        proposedDriver.driverAddress=address(0);
        proposedDriver.salary=0;
        proposedDriver.approvedState=0;
        //
        carDriver=address(0);
        //TODO:delete
        carDriverBalance=0;
        carDriverExpectedSalary=0;
        //future ten years
        carDriverMontly=1968145216;
    }

    function join() public payable isNotCarDealer isNotOwner{
        console.log("In Join");
        //check is array is full
        require (participants.length <=9 ,"Participant list is full");
        //check msg sender have enough fee
        require (msg.value >= participantFee,"Not enough participant fee to enter");
        //check msg sender is already in array
        for(uint i=0;i<participants.length;i++){
            require (participants[i] != msg.sender ,"You are in the participant list");
        }
        //project participantFee is added to projject balance
        balance = balance + participantFee;
        //add msg sender to participants array
        participants.push(msg.sender);
        /*old version
        //msg sender account's balance update
        //projectOwner.transfer(participantFee);
        */
        //return the more that participant fee to the msg.sender
        payable(msg.sender).transfer(msg.value-participantFee);

    }
  
    //proposition to buy car , car dealer can call
    function CarProposeToBusiness(uint64 carID, uint price, uint offerTime) public isCarDealer {
        console.log("In CarProposeToBusiness to buy car");
        //check porposed car is assigned before
        require(proposedCar.id == 0, "Cannot call this function again, please call RepurchaseCarPropose");
        //assign the proposed car
        proposedCar.id=carID;
        proposedCar.price=price;
        proposedCar.validTime=block.timestamp+offerTime;
        proposedCar.approvedState=0;
    }

    //approved address array to buy car
    address[] purchasedCarAddress;
    bool isCarBought=false;

    function ApprovePurchaseCar() public isParticipant isNotApprovedForBuy {
        console.log("In ApprovePurchaseCar");
        require(proposedCar.id != 0,"There is no info about car");
        //update approved state
        proposedCar.approvedState++;
        //add approved to array
        purchasedCarAddress.push(msg.sender);
        console.log("%s %s %s",participants.length/2,proposedCar.approvedState,balance);
        //check the balance is enough
        require(address(this).balance>=proposedCar.price,"Not enouh money to buy car");
        //check the timer is expire or not
        require(block.timestamp <= proposedCar.validTime,"timer is expired to buy car");
        //check the flag to stop buy twice or more
        require(carID!=proposedCar.id,"You have bought this car before");
        //check majority is approved
        if(participants.length/2<proposedCar.approvedState){
            console.log("Go to PurchaseCar");
            PurchaseCar();
        }
    }

    function PurchaseCar()  public  payable /*carIDCheck*/{
        console.log("In PurchaseCar");
        //TODO: delete
        //carDealerBalance=carDealerBalance+proposedCar.price;
        //TODO: delete
        //balance=balance-proposedCar.price;
        payable(carDealer).send(proposedCar.price);
        //uodate flag
        isCarBought=true;
        //clear approved array to buy car 
        removeAllAddressFromArray(purchasedCarAddress);
        //update carID
        carID=proposedCar.id;
        //update car expenses timer
        carExpensesTimer=block.timestamp;
    }
    
    //proposition to sell car , car dealer can call, car dealer buy the car, participants sell car
    function RepurchaseCarPropose(uint64 carID, uint price, uint offerTime) public isCarDealer {
        console.log("In RepurchaseCarPropose to sell car");
        //check the proposed car is assigned or not 
        require(proposedCar.id != 0, "Cannot call this function before CarProposeToBusiness");
        //assign the proposed purchase
        proposedPurchase.id=carID;
        proposedPurchase.price=price;
        proposedPurchase.validTime=block.timestamp+offerTime;
        proposedPurchase.approvedState=0;
    }


    //selling the car 
    //approved address array 
    address[] repurchasedCarAddress;
    
    //this function name must be changed
    function ApproveSellProposal() public isParticipant isNotApprovedForSell {
        console.log("In ApproveSellProposal");
        require(proposedPurchase.id !=0 ,"Proposed Purchase is not initialize");
        //update approved state
        proposedPurchase.approvedState++;
        //add aproved address to approved array
        repurchasedCarAddress.push(msg.sender);
        //check the balance is enough
        require(address(this).balance>=proposedPurchase.price,"Not enough money to buy car");
        //check the timer is expire or not
        require(block.timestamp <= proposedPurchase.validTime,"timer is expired to buy car");

        console.log("%s %s %s",participants.length/2,proposedPurchase.approvedState,address(this).balance);
        //check majority is approved
        if(participants.length/2<proposedPurchase.approvedState){
            console.log("Go to RepurchaseCar");
            Repurchasecar();
        }
    }

    //ın this function is called by car delaer to get money from car dealer. i dont understand clearly this function
    function Repurchasecar()  public payable {
        console.log("In RepurchaseCar");
        //send price to buy second car but there is a dilemma, i dont understand clearly
        payable(carDealer).send(proposedPurchase.price);
        //clear approved array to sell car
        removeAllAddressFromArray(repurchasedCarAddress);
        //update car id
        carID=proposedPurchase.id;
        //after selling the car isCarBought flag update
        isCarBought=true;
        //update timer 
        carExpensesTimer=block.timestamp;
    }

    //proposition of driver , owner,participants and car dealer can not call
    //flag to check driver is approved
    bool isDriverApproved=false;
    function ProposeDriver(uint salary) public /*isNotCarDealer isNotOwner isNotParticipant*/{
        console.log("In ProposeDriver to propose driver");
        //get driver address
        proposedDriver.driverAddress=msg.sender;
        //assign dirver salary
        proposedDriver.salary=salary;
        //update approved state
        proposedDriver.approvedState=0;
    }


    //assign the driver
    //approved address array 
    address[] approvedTheDriver;
    function ApproveDriver() public isParticipant isDriverApprovedBefore{
        console.log("In ApproveDriver");
        //check the driver infos are updated
        require(proposedDriver.driverAddress !=address(0),"There is no driver informations");
        //update driver counter
        proposedDriver.approvedState++;
        //push approved participant to array
        approvedTheDriver.push(msg.sender);
        console.log("%s %s",participants.length/2,proposedDriver.approvedState);
        //check majority is approved
        if(participants.length/2<proposedDriver.approvedState){
            console.log("Go to SetDriver");
            SetDriver();
        }
    }

    function SetDriver() public{
        console.log("In SetDriver");
        carDriver=proposedDriver.driverAddress;
        carDriverExpectedSalary=proposedDriver.salary;
        //clear approved array to sell car
        removeAllAddressFromArray(approvedTheDriver);
        //after setting driver flag must be changed
        isDriverApproved=true;
        //update timer
        carDriverMontly=block.timestamp;
    }


    //fire driver 
    address[] fireDriverApprovedAddress;
    function ProposeFireDriver() public isParticipant isDriverApprovedChecker{
        console.log("In ProposeFireDriver to fire driver");
        //add approvet account to array
        fireDriverApprovedAddress.push(msg.sender);
        //check majority
        if(participants.length/2<fireDriverApprovedAddress.length ){
            console.log("Go to FireDriver");
            FireDriver();
        }
    }
    function FireDriver() public payable{
        console.log("In FireDriver");
        //send one month salary
        payable(carDriver).transfer(carDriverExpectedSalary);

        //clear drivers infos.
        carDriver=address(0);
        carDriverExpectedSalary=0;
        carDriverBalance=0;
        //clear approved array to sell car
        removeAllAddressFromArray(fireDriverApprovedAddress);
        //after selling the car isCarBought flag must be changed
        isDriverApproved=false;
    }

    function LeaveJob() public isCarDriver{
        FireDriver();
    }

    //get charge function
    function GetCharge() public payable {
        // do nothing
        // msg.value is automaticlly add to address(this).balance
        //this function takes whatever send from customer to address(this).balance
        
    }

    function GetSalary() public payable passOnemonth isCarDriver{
        //update one month timer
        carDriverMontly=block.timestamp;
        /*
        balance=balance-carDriverExpectedSalary;
        carDriverBalance=carDriverBalance+carDriverExpectedSalary;
        */
        //pay car driver
        payable(carDriver).transfer(carDriverExpectedSalary);
    }
    //todo check balance, transfer ethers
    function CarExpenses() public payable passSixmonth isParticipant{
        //update six month timer
        carExpensesTimer=block.timestamp;
        /*
        balance=balance-fixedExpenses;
        carDealerBalance=carDealerBalance+fixedExpenses;
        */
        //pay car dealer
        payable(carDealer).transfer(fixedExpenses);
    }
    uint profitPerParticipant=0;
    mapping(address=>uint256)  profitBalances;
    function PayDividend() public isParticipant passSixmonthPayDividend{
        //calculate profit for each participant
        profitPerParticipant=(address(this).balance-fixedExpenses-carDriverExpectedSalary)/participants.length;
        //assign profit to participants' address
        for(uint i=0;i<participants.length;i++){
            profitBalances[participants[i]] = profitPerParticipant;
        }
    }

    function GetDividend() public isParticipant {
        //check the user's balance if not zero, user get his/her balance
        if(profitBalances[msg.sender]>0){
            console.log("Profit istransfered to participant address");
            payable(msg.sender).transfer(profitBalances[msg.sender]);
            profitBalances[msg.sender]=0;
        }
        //if user balance is 0, log message
        else{
            console.log("There is no profit for this participant");
        }
    }


    //get ca dealer address
    function getCarDealerAddress() public view returns(address ){
        return carDealer;
    }
    //get car infos which participants want to buy.
    function getCarProposeToBusiness() public view returns(proposalCarStruct memory){
        return proposedCar;
    }
    //get car infos which participants want to sell.
    function getCarProposeToSell() public view returns(proposalCarStruct memory){
        return proposedPurchase;
    }

    //fall back function
    fallback() external payable
    {

    }
    
    


    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getCarDealerBalance() public view returns(uint){
        return carDealer.balance;
    }
    function getCarDriverBalance() public view returns(uint){
        return carDriverBalance;
    }
      //get owner address
    function getOwnerAddress() public view returns (address){
        return projectOwner;
    }
    
    
    //clear the array entirely
    function removeAllAddressFromArray (address[] memory arrayAddress) private{
        console.log("Clear approved array ");
        for(uint i=0;i<arrayAddress.length;i++){
            arrayAddress[i]=address(0);
        }
    }

    //src: https://stackoverflow.com/questions/55345063/how-to-return-array-of-address-in-solidity
    function getParticipants()public view returns( address  [] memory){
        return participants;
    }
    
    ////**************************** MODIFIERS ********************////
    //check is owner or not
    modifier isOwner() {
        require(msg.sender == projectOwner, "It is not manager");
        _;
    }
    //check car dealer is assigned
    modifier carDealerAssigned() {
        require(carDealerIsAssigned == false, "Car dealer is assigned, cannot assigned now");
        _;
    }

    //check proposed is first or not
    modifier proposedOnceCarFromCarDealer() {
        require(proposedCar.validTime == 0, "Proposal is sent, from car dealer");
        _;
    }

    //check carDealer balance
    modifier checkCarDealerBalance() {
        require(carDealer.balance >= proposedPurchase.price, "Car dealer has not enough money to buy car");
        _;
    }
    //check car is bought or not
    modifier isCarBoughtFromParticipants() {
        require(isCarBought == true, "no car bought, cannot call this function");
        _;
    }
    //check proposed before ?
    modifier proposedAfterOnceCarFromCarDealer() {
        require(proposedCar.validTime != 0, "Proposal is sent, from car dealer");
        _;
    }
    //check car id is update or not
    modifier carIDCheck() {
        require(proposedCar.id != carID, "you buy this car before, cannot buy again");
        _;
    }
    //check driver is not approved
    modifier isDriverApprovedBefore() {
        require(isDriverApproved == false, "Driver is approved before");
        _;
    }
    //check driver is approved
    modifier isDriverApprovedChecker() {
        require(isDriverApproved == true, "Driver is not approved before");
        _;
    }
    //check one month is passed
    modifier passOnemonth() { 
        //3000000 is montly time   
        require(carDriverMontly+3000000 <= block.timestamp, "One month not pass");
        _;
    }
    //check six months are passed
    modifier passSixmonth() { 
        //6*3000000 is montly time   
        require(carExpensesTimer+3000000*6 <= block.timestamp, "Six months not pass");
        _;
    }
    //check participant pay divident timer 
    modifier passSixmonthPayDividend() { 
        //3000000 is montly time   
        require(payDividendTimer+3000000*6 <= block.timestamp, "Six months not pass");
        _;
    }

    //check approved array to buy
    modifier isNotApprovedForBuy() {
        for(uint i=0;i<purchasedCarAddress.length;i++){
            require (purchasedCarAddress[i] != msg.sender ,"You have approved to buy car");
        }
        _;
    }
    //check approved array to sell
    modifier isNotApprovedForSell() {
        for(uint i=0;i<repurchasedCarAddress.length;i++){
            require (repurchasedCarAddress[i] != msg.sender ,"You have approved to sell car" );
        }
        _;
    }
    //check approved array to driver set
    modifier isNotApprovedForDriverSet() {
        for(uint i=0;i<approvedTheDriver.length;i++){
            require (approvedTheDriver[i] != msg.sender ,"You have approved to set driver");
        }
        _;
    }
    //check anot participant
    modifier isNotParticipant() {
        for(uint i=0;i<participants.length;i++){
            require (participants[i] != msg.sender ,"You are in the participant list");
        }
        _;
    }
    //check not owner
    modifier isNotOwner() {
        require(msg.sender != projectOwner, "You are manager, not participant");
        _;
    }
    //check car driver
    modifier isCarDriver() {
        require(msg.sender == carDriver, "You are not driver ");
        _;
    }
    
    // modifier to check if caller is car dealer
    modifier isCarDealer() {
        require(msg.sender == carDealer, "Caller is not car dealer");
        _;
    }
    //check not car dealer
    modifier isNotCarDealer() {
        require(msg.sender != carDealer, "You are car dealer, not participant");
        _;
    }
    // modifier to check if caller is participant
    modifier isParticipant() {
        bool isOk=false;
        for (uint i=0; i<participants.length; i++) {
            if(participants[i]==msg.sender){
                isOk=true;
            }
        }
        require(isOk, "Caller is not participant");
        _;
    }

    ////**************************** MODIFIERS ********************////

    /*function getOwnerAddress() public view returns (address){
        return projectOwner;
    }
    function  setMsgSender  (address senderAddress) public{
        projectOwner = payable(senderAddress);
    }
    
    function getAccountBalance() public view returns (uint ){
        return msg.sender.balance;
    }

    function getTimerForFixedExpenses() public view returns (uint256){
        return timerForFixedExpenses;
    }
    function setTimerForFixedExpenses() public{
        timerForFixedExpenses = block.timestamp;
    }

    function getParticipantFee() public view returns (uint){
        return participantFee;
    }
    function setPariticipantFee(uint participantFeeSet) public{
        participantFee = participantFeeSet;
    }

    function getFixedExpenses() public view returns (uint){
        return fixedExpenses;
    }
    function setFixedExpenses(uint fixedExpensesSet) public{
        fixedExpenses = fixedExpensesSet;
    }
    function getBalance() public view returns (uint){
        return balance;
    }
    function setBalance(uint balanceSet) public{
        balance = balanceSet;
    }*/

    /*function setParticipantAddress(address payable participanfAddress) public{
        participants[participantIndex] = participanfAddress;
        participantIndex++;
    }
    function getParticipantAddress() public view returns (address participants2){
        return participants[participantIndex-1];
    }*/
}