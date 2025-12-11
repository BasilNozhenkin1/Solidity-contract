const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CollateralizedLoan", function () {

  async function deployCollateralizedLoanFixture() {
    const [owner, borrower, lender] = await ethers.getSigners();

    const CollateralizedLoan = await ethers.getContractFactory("CollateralizedLoan");
    const collateralizedLoan = await CollateralizedLoan.deploy();

    return { collateralizedLoan, owner, borrower, lender };
  }

  describe("Loan Request", function () {
    it("Should let a borrower deposit collateral and request a loan", async function () {
      const { collateralizedLoan, borrower } = await loadFixture(deployCollateralizedLoanFixture);

      const collateralAmount = ethers.parseEther("1.0");
      const interestRate = 16;//my country interest rate
      const duration = 1;

      await collateralizedLoan
      .connect(borrower)
      .depositCollateralAndRequestLoan(interestRate, duration, {
        value: collateralAmount
      });
      //first loan
      const loanId = 0;
      const loan = await collateralizedLoan.loans(loanId);
      expect(loan.borrower).to.equal(borrower.address);
      expect(loan.collateralAmount.toString()).to.equal(collateralAmount.toString());
      expect(loan.interestRate).to.equal(interestRate);
      expect(loan.isFunded).to.equal(false);
      expect(loan.isRepaid).to.equal(false);
    });
  });

  describe("Funding a Loan", function () {
    it("Allows a lender to fund a requested loan", async function () {
      // TODO: implement test
      const { collateralizedLoan, borrower, lender } = await loadFixture(deployCollateralizedLoanFixture);

      const collateralAmount = ethers.parseEther("1.0");
      const interestRate = 16;
      const duration = 1;

      await collateralizedLoan
        .connect(borrower)
        .depositCollateralAndRequestLoan(interestRate, duration, {
          value: collateralAmount,
        });
      
      const loanId = 0;
      const loanData = await collateralizedLoan.loans(loanId);

      await collateralizedLoan
      .connect(lender)
      .fundLoan(loanId, 
        { 
          value: loanData.loanAmount 
        }
      )

      const updated = await collateralizedLoan.loans(loanId);
      expect(updated.isFunded).to.equal(true);
      expect(updated.lender).to.equal(lender.address);
    });
  });

  describe("Repaying a Loan", function () {
    it("Enables the borrower to repay the loan fully", async function () {
      // TODO: implement test
      const { collateralizedLoan, borrower, lender } = await loadFixture(deployCollateralizedLoanFixture);

      const collateralAmount = ethers.parseEther("1.0");
      const interestRate = 16;
      const duration = 1;

      await collateralizedLoan
        .connect(borrower)
        .depositCollateralAndRequestLoan(interestRate, duration, {
          value: collateralAmount,
        });

      const loanId = 0;
      const loanData = await collateralizedLoan.loans(loanId);
      const interest = (loanData.loanAmount * loanData.interestRate) / 100n;
      const totalRepayment = loanData.loanAmount + interest;
 
      await collateralizedLoan
      .connect(borrower)
      .repayLoan(loanId, {
        value: totalRepayment + 1n
      })

      const updated = await collateralizedLoan.loans(loanId);
      expect(updated.isRepaid).to.equal(true);
    });
  });

  describe("Claiming Collateral", function () {
    it("Permits the lender to claim collateral if the loan isn't repaid on time", async function () {
      // TODO: implement test
      const { collateralizedLoan, borrower, lender  } = await loadFixture(deployCollateralizedLoanFixture);

      const collateralAmount = ethers.parseEther("1.0");
      const interestRate = 16;
      const duration = 1;

      await collateralizedLoan
        .connect(borrower)
        .depositCollateralAndRequestLoan(interestRate, duration, {
          value: collateralAmount,
        });

      const loanId = 0;
      const loanData = await collateralizedLoan.loans(loanId);

      //lender funds
      await collateralizedLoan
      .connect(lender)
      .fundLoan(loanId, {
        value: loanData.loanAmount,
      });

      //time passed
      await ethers.provider.send("evm_increaseTime", [2000]);
      await ethers.provider.send("evm_mine");


      await collateralizedLoan
      .connect(lender)
      .claimCollateral(loanId)

      const updated = await collateralizedLoan.loans(loanId);
      expect(updated.isRepaid).to.equal(true);
    });
  });
});
