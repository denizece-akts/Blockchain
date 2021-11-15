pragma solidity >=0.7.0 <0.8.0;
 
contract SharedTaxiBusiness {

    struct Participant{
        uint balance;
        mapping (address => bool) participants;
    }
    Participant Participants;
    address payable[] public Participants_Array;
    
    address payable public Car_Dealer;
    address public Manager;
    uint32 public Owned_Car;
    
    uint constant Participation_Fee=100 ether;
    uint constant Fixed_Expenses=10 ether;
    
    struct Taxi_Driver {
        address payable addr;
        uint salary;
        uint lastPaid;
    }
    
    struct Proposed_Driver {
        Taxi_Driver taxi_Driver;
        uint Approval_State;
        mapping (address => bool) Approved_Votes;
    }
    
    Taxi_Driver public taxiDriver;
    Proposed_Driver  proposed_Driver;
    
    struct Proposed {
        uint32 carID;
        uint price;
        uint Offer_Valid_Time;
        uint Approval_State;
        mapping (address => bool) Approved_Votes;
    }
    
    Proposed proposed_Car;
    Proposed proposed_Repurchased_Car;
    
    uint public lastSalaryTime;
    uint public lastChargeTime;
    uint public lastExpensesTime;
    uint public lastDividedTime;
    uint public income;
    uint public expenses;
    
    //Modifiers
    modifier onlyManager(){
        require(Manager == msg.sender);
        _;
    }
    modifier onlyParticipant() {
        require(Participants.participants[msg.sender]);
        _;
    }
    modifier onlyCarDealer(){
        require(Car_Dealer == msg.sender);
        _;
    }
    modifier onlyDriver() {
        require(taxiDriver.addr == msg.sender);
        _;
    }
    
    //Constructors
    
    constructor() public { 
        Manager = msg.sender;
        Participants.balance=0;
        income = 0;
        expenses = 0;
        lastDividedTime = block.timestamp;
        lastExpensesTime = block.timestamp;
        lastSalaryTime = block.timestamp;
        lastChargeTime = block.timestamp;
    }
    
    //functions
    
    function join() public payable {            //participants join at most 9 participants
        require(msg.value >= Participation_Fee && Participants_Array.length < 9);
        Participants.participants[msg.sender] = true;
        Participants_Array.push(msg.sender);
    }
    
    function setCarDealer(address payable carDealer) public onlyManager {       //set car dealers address
        require(carDealer != address(0));       //given address shouldn't be empty
        Car_Dealer = carDealer;
    }
    
    function carProposeToBusiness(uint32 carID, uint price, uint Offer_Valid_Time) public onlyCarDealer {       //sets proposed car values
        proposed_Car.carID = carID;
        proposed_Car.price=price;
        proposed_Car.Offer_Valid_Time=Offer_Valid_Time;
        proposed_Car.Approval_State=0;
        proposed_Car.Approved_Votes[msg.sender]=false;
    }
    
    function approvePurchaseCar() public onlyParticipant {          //approves the car purchase
        require(proposed_Car.Approved_Votes[msg.sender]==false);           //proposed car shouldn't be approved before      
        proposed_Car.Approval_State =proposed_Car.Approval_State + 1;
        proposed_Car.Approved_Votes[msg.sender] = true;
    }
    
    function purchaseCar() public onlyManager payable{      //car is purchased
        require(block.timestamp < proposed_Car.Offer_Valid_Time && proposed_Car.Approval_State > Participants_Array.length / 2);        //if time didn't pass and if more than half has approved
        Car_Dealer.transfer(proposed_Car.price);
        Owned_Car = proposed_Car.carID;
        proposed_Car.Offer_Valid_Time = block.timestamp; 
    } 
    
    function repurchaseCarPropose(uint32 carID, uint price, uint offerValidTime) public onlyCarDealer {     //sets proposed repurchase car values
        proposed_Repurchased_Car.carID = carID;
        proposed_Repurchased_Car.price = price;
        proposed_Repurchased_Car.Offer_Valid_Time = offerValidTime;
        proposed_Repurchased_Car.Approval_State = 0;
        proposed_Repurchased_Car.Approved_Votes[msg.sender] = false;
    }
    
    function approveSellProposal() public onlyParticipant {         //approves the car purchase
        require(proposed_Repurchased_Car.Approved_Votes[msg.sender] == false);      //proposed car shouldn't be approved before  
        proposed_Repurchased_Car.Approval_State = proposed_Repurchased_Car.Approval_State + 1;
        proposed_Repurchased_Car.Approved_Votes[msg.sender] = true;
    }
    
    function repurchaseCar() public onlyCarDealer payable {         //car is repurchased
        require(block.timestamp < proposed_Repurchased_Car.Offer_Valid_Time && proposed_Repurchased_Car.Approval_State > Participants_Array.length / 2);        //if time didn't pass and if more than half has approved
        Car_Dealer.transfer(proposed_Repurchased_Car.price);
        Owned_Car = proposed_Repurchased_Car.carID;
        proposed_Repurchased_Car.Offer_Valid_Time = block.timestamp; 
    }
    
    function proposeDriver(address payable driverAddress, uint salary) public onlyManager{      //driver is proposed
        require(driverAddress != address(0));           //given driver address shouldn't be empty
        proposed_Driver.taxi_Driver.addr = driverAddress;
        proposed_Driver.taxi_Driver.salary = salary;
        proposed_Driver.taxi_Driver.lastPaid = 0;
        proposed_Driver.Approved_Votes[msg.sender]=false;
    }
    
    function approveDriver() public onlyParticipant {       //driver is approved
        require(proposed_Driver.Approved_Votes[msg.sender] == false);       //driver shouldn't be approved before
        proposed_Driver.Approval_State = proposed_Driver.Approval_State + 1;
        proposed_Driver.Approved_Votes[msg.sender] = true;
    }
    
    function setDriver() public onlyManager {           //driver is set
        require(proposed_Driver.Approval_State > Participants_Array.length / 2);        //driver is approved by more than half
        taxiDriver = proposed_Driver.taxi_Driver;
    }
    
    function fireDriver() public onlyManager payable{       //driver is fired
        require(taxiDriver.addr != address(0));        //given taxi driver's addres can't be empty and 
        taxiDriver.addr.transfer(taxiDriver.salary);
        taxiDriver.addr = address(0);       //because driver fired struct is turned to default
        taxiDriver.salary = 0;
        taxiDriver.lastPaid = 0; 
    }
    
    function payTaxiCharge() payable public {       //charge is sent to contract which is income variable
        income = income + msg.value;
        lastChargeTime = block.timestamp;
    }
    
    function releaseSalary() public onlyManager payable{        //salary is relaesed
        require(block.timestamp >= taxiDriver.lastPaid + 30 days);      //allow salary release only once a month
        taxiDriver.addr.transfer(taxiDriver.salary);
        expenses = expenses + taxiDriver.salary;
        taxiDriver.lastPaid = block.timestamp;
        lastSalaryTime =block.timestamp;
    }
    
    function getSalary() public onlyDriver payable{     //driver gets salary into their account
        require(taxiDriver.salary > 0);
        taxiDriver.addr.transfer(taxiDriver.salary);
    }
    
    function payCarExpenses() public onlyManager payable{       //pay car expences every 6 month
        require(Car_Dealer != address(0) && block.timestamp >= lastExpensesTime + 182 days);        //car dealer's address shouldn't be empty
        Car_Dealer.transfer(Fixed_Expenses);
        expenses = expenses + Fixed_Expenses;
        lastExpensesTime = block.timestamp;
    }
    
    function payDivided() public onlyManager payable{           //pay divided
        require(block.timestamp >= lastDividedTime + 182 days);     //allow pay division once every 6 months
        uint profit = income - expenses;
        require(profit > 0);        //profit should be more than 0
        uint patNum = Participants_Array.length;
        while (patNum>=0){
            Participants_Array[patNum].transfer(profit/Participants_Array.length);
            patNum = patNum - 1;
        }
        lastDividedTime = block.timestamp;
    }
    
    function getDivided() public onlyParticipant payable{       //participant gets their balance into their account 
        require(Participants.balance > 0);
        msg.sender.transfer(Participants.balance);      //normally I was going to transfer to participants_array but participants_array[msg.sender] gives error
    }
    
    //fallback
   fallback() external  {
        revert();
    }     
    
}