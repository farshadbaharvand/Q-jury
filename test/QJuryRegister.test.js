const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("JuryRegistry Contract", function () {
  let juryRegistry;
  let admin, juror1, juror2;
  const minStake = ethers.parseEther("1"); // حداقل 1 ETH

  beforeEach(async () => {
    [admin, juror1, juror2] = await ethers.getSigners();

    const JuryRegistryFactory = await ethers.getContractFactory("JuryRegistry", admin);
    juryRegistry = await JuryRegistryFactory.deploy(minStake);
  });

  it("should set admin and minStake correctly", async () => {
    expect(await juryRegistry.admin()).to.equal(admin.address);
    expect(await juryRegistry.minStake()).to.equal(minStake);
  });

  it("should allow user to register as juror", async () => {
    await juryRegistry.connect(juror1).registerAsJuror();
    const juror = await juryRegistry.jurors(juror1.address);
    expect(juror.isRegistered).to.be.true;
  });

  it("should not allow double registration", async () => {
    await juryRegistry.connect(juror1).registerAsJuror();
    await expect(juryRegistry.connect(juror1).registerAsJuror())
      .to.be.revertedWith("You are already registered.");
  });

  it("should allow registered juror to deposit stake", async () => {
    await juryRegistry.connect(juror1).registerAsJuror();
    await juryRegistry.connect(juror1).depositStake({ value: minStake });

    const juror = await juryRegistry.jurors(juror1.address);
    expect(juror.stakeAmount).to.equal(minStake);
    expect(juror.hasStaked).to.be.true;
  });

  it("should revert depositStake if juror is not registered", async () => {
    await expect(
      juryRegistry.connect(juror2).depositStake({ value: minStake })
    ).to.be.revertedWith("You must register first.");
  });

  it("should revert depositStake if stake amount too low", async () => {
    await juryRegistry.connect(juror1).registerAsJuror();
    await expect(
      juryRegistry.connect(juror1).depositStake({ value: ethers.parseEther("0") })
    ).to.be.revertedWith("Stake amount too low.");
  });

  it("should revert if juror tries to stake twice", async () => {
    await juryRegistry.connect(juror1).registerAsJuror();
    await juryRegistry.connect(juror1).depositStake({ value: minStake });

    await expect(
      juryRegistry.connect(juror1).depositStake({ value: minStake })
    ).to.be.revertedWith("Stake already deposited.");
  });

  it("should allow admin to reward juror and refund stake", async () => {
    await juryRegistry.connect(juror1).registerAsJuror();
    await juryRegistry.connect(juror1).depositStake({ value: minStake });

    const initialBalance = await ethers.provider.getBalance(juror1.address);

    const tx = await juryRegistry.connect(admin).rewardJuror(juror1.address);
    await tx.wait();

    const juror = await juryRegistry.jurors(juror1.address);
    expect(juror.stakeAmount).to.equal(0);
    expect(juror.hasStaked).to.be.false;
  });

  it("should revert rewardJuror if caller is not admin", async () => {
    await juryRegistry.connect(juror1).registerAsJuror();
    await juryRegistry.connect(juror1).depositStake({ value: minStake });

    await expect(
      juryRegistry.connect(juror2).rewardJuror(juror1.address)
    ).to.be.revertedWith("Only admin can reward jurors.");
  });

  it("should revert rewardJuror if juror has no stake", async () => {
    await expect(
      juryRegistry.connect(admin).rewardJuror(juror1.address)
    ).to.be.revertedWith("Juror has no stake to return.");
  });

  it("should allow admin to slash juror stake", async () => {
    await juryRegistry.connect(juror1).registerAsJuror();
    await juryRegistry.connect(juror1).depositStake({ value: minStake });

    await juryRegistry.connect(admin).slashJuror(juror1.address);

    const juror = await juryRegistry.jurors(juror1.address);
    expect(juror.stakeAmount).to.equal(0);
    expect(juror.hasStaked).to.be.false;
  });

  it("should revert slashJuror if caller is not admin", async () => {
    await juryRegistry.connect(juror1).registerAsJuror();
    await juryRegistry.connect(juror1).depositStake({ value: minStake });

    await expect(
      juryRegistry.connect(juror2).slashJuror(juror1.address)
    ).to.be.revertedWith("Only admin can slash jurors.");
  });

  it("should revert slashJuror if juror has no stake", async () => {
    await expect(
      juryRegistry.connect(admin).slashJuror(juror1.address)
    ).to.be.revertedWith("Juror has no stake to slash.");
  });

  it("should return the correct contract balance", async () => {
    await juryRegistry.connect(juror1).registerAsJuror();
    await juryRegistry.connect(juror1).depositStake({ value: minStake });

    const balance = await juryRegistry.getContractBalance();
    expect(balance).to.equal(minStake);
  });
});
