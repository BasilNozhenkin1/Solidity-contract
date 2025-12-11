// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Collateralized Loan Contract
contract CollateralizedLoan {
    // Loan structure
    struct Loan {
        address borrower;
        address lender;
        uint collateralAmount;
        uint loanAmount;
        uint interestRate;
        uint dueDate;
        bool isFunded;
        bool isRepaid;
    }

    // Create a mapping to manage the loans
    mapping(uint => Loan) public loans;
    //starting from 0 now
    uint public nextLoanId = 0;
  
  
    // Hint: Define events for loan requested, funded, repaid, and collateral claimed
    event LoanRequested(uint loanId, address borrower, uint collateralAmount, uint loanAmount, uint interestRate, uint dueDate);
    event LoanFunded(uint loanId, address lender);
    event LoanRepaid(uint loanId);
    event CollateralClaimed(uint loanId, address lender);
    // Custom Modifiers
    // Hint: Write a modifier to check if a loan exists
    
    modifier validLoan(uint _loanId) {
        //now it starts from 0 so we need to change it
        require( _loanId < nextLoanId, "Loan does not exist");
        _;
    }
    // Hint: Write a modifier to ensure a loan is not already funded
    modifier loanIsNotFunded(uint _loanId) {
        require(!loans[_loanId].isFunded , "Loan is already funded");
        _;
    }
    modifier loanFunded(uint _loanId) {
        require(loans[_loanId].isFunded, "Loan is not funded yet");
        _;
    }

     modifier onlyBorrower(uint _loanId) {
        require(loans[_loanId].borrower == msg.sender, "Only borrower has access to this action");
        _;
    }

    modifier onlyLender(uint _loanId) {
        require(loans[_loanId].lender == msg.sender, "Only lender has access to this action");
        _;
    }

    modifier notRepaid(uint _loanId) {
        require(!loans[_loanId].isRepaid, "Loan is already repaid");
        _;
    }
    // Function to deposit collateral and request a loan
    function depositCollateralAndRequestLoan(uint _interestRate, uint _duration) external payable {
        // Hint: Check if the collateral is more than 0
        uint collateral = msg.value; 
        //Some additional validation
        require(collateral > 0, "Collateral must be greater than 0");
        require(_interestRate > 0 && _interestRate < 99, "Interest rate must be a number less then 100");
        require(_duration > 0, "Duration must be greater than 0");

        uint loanId = nextLoanId;

        uint dueDate = block.timestamp + _duration;
        // Hint: Calculate the loan amount based on the collateralized amount
        //Basic algo
        uint loanAmount = (collateral * 100) / (100 + _interestRate);
        // Hint: Increment nextLoanId and create a new loan in the loans mapping
        nextLoanId += 1;
        
    
        loans[loanId] = Loan({
            borrower: msg.sender,
            lender: address(0),
            collateralAmount: msg.value,
            loanAmount: loanAmount,
            interestRate: _interestRate,
            dueDate: dueDate,
            isFunded: false,
            isRepaid: false
        });

        // Hint: Emit an event for loan request
        emit LoanRequested(loanId, msg.sender, collateral, loanAmount, _interestRate, dueDate);
    }

  
    // Function to fund a loan
    // Hint: Write the fundLoan function with necessary checks and logic
    //fixed typo
    function fundLoan(uint _loanId) public payable  
        validLoan(_loanId)
        loanIsNotFunded(_loanId) {

        Loan storage loan = loans[_loanId];
        require(msg.value >= loan.loanAmount, "Insufficient amount of funds for loan");
        loan.lender = msg.sender;
        loan.isFunded = true;
        //send & transfer available for payable onnly
        payable(loan.borrower).transfer(loan.loanAmount);

        emit LoanFunded(_loanId, msg.sender);
    }

    // Function to repay a loan
    // Hint: Write the repayLoan function with necessary checks and logic
    function repayLoan(uint _loanId) public payable 
        validLoan(_loanId)
        loanIsNotFunded(_loanId)
        notRepaid(_loanId) {
        Loan storage loan = loans[_loanId];

        uint interestAmount = (loan.loanAmount * loan.interestRate) / 100;
        uint totalRepayment = loan.loanAmount + interestAmount;
        //we should be able pay the required price, so yes = taken into account
        require(msg.value >= totalRepayment, "Insufficient amount to repay loan");

        loan.isRepaid = true;

        payable(loan.lender).transfer(totalRepayment);
        
        // Return collateral to borrower
        payable(loan.borrower).transfer(loan.collateralAmount);

        emit LoanRepaid(_loanId);
    }
    // Function to claim collateral on default
    // Hint: Write the claimCollateral function with necessary checks and logic
    function claimCollateral(uint _loanId) public payable 
        validLoan(_loanId)
        loanFunded(_loanId)
        notRepaid(_loanId)
        onlyLender(_loanId) {
        Loan storage loan = loans[_loanId];
        require(block.timestamp > loan.dueDate, "Loan is not overdue yet");

        loan.isRepaid = true;
        payable(loan.lender).transfer(loan.collateralAmount);

        emit CollateralClaimed(_loanId, msg.sender);
    }
    
    function getLoanCount() public view returns (uint) {
        return nextLoanId; 
    }
}