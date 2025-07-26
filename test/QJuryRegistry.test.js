const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("QJuryRegistry", function () {
  let registry, juror1, juror2, juror3;
  const STAKE_AMOUNT = ethers.utils.parseEther("0.1");

  beforeEach(async () => {
    [owner, juror1, juror2, juror3] = await ethers.getSigners();

    const Registry = await ethers.getContractFactory("QJuryRegistry");
    registry = await Registry.deploy();
    await registry.deployed();
  });

  it("should allow a juror to register with exact stake", async () => {
    await expect(
      registry.connect(juror1).registerAsJuror({ value: STAKE_AMOUNT })
    )
      .to.emit(registry, "JurorRegistered")
      .withArgs(juror1.address);

    const isRegistered = await registry.isJuror(juror1.address);
    expect(isRegistered).to.be.true;
  });

  it("should not allow registration with incorrect stake", async () => {
    await expect(
      registry.connect(juror1).registerAsJuror({ value: ethers.utils.parseEther("0.05") })
    ).to.be.revertedWith("Incorrect stake");
  });

  it("should not allow double registration", async () => {
    await registry.connect(juror1).registerAsJuror({ value: STAKE_AMOUNT });
    await expect(
      registry.connect(juror1).registerAsJuror({ value: STAKE_AMOUNT })
    ).to.be.revertedWith("Already registered");
  });

  it("should return correct list of jurors", async () => {
    await registry.connect(juror1).registerAsJuror({ value: STAKE_AMOUNT });
    await registry.connect(juror2).registerAsJuror({ value: STAKE_AMOUNT });

    const jurors = await registry.getAllJurors();
    expect(jurors).to.include(juror1.address);
    expect(jurors).to.include(juror2.address);
  });

  it("should slash juror and update state", async () => {
    await registry.connect(juror1).registerAsJuror({ value: STAKE_AMOUNT });

    await expect(registry.connect(owner).slashJuror(juror1.address))
      .to.emit(registry, "JurorSlashed")
      .withArgs(juror1.address);

    const isStillJuror = await registry.isJuror(juror1.address);
    expect(isStillJuror).to.be.false;
    expect(await registry.stakes(juror1.address)).to.equal(0);
  });

  it("should revert if slashing a non-juror", async () => {
    await expect(
      registry.connect(owner).slashJuror(juror2.address)
    ).to.be.revertedWith("Not a juror");
  });

  it("should reward a juror by transferring ETH", async () => {
    await registry.connect(juror1).registerAsJuror({ value: STAKE_AMOUNT });

    const rewardAmount = ethers.utils.parseEther("0.02");

    // Fund contract
    await owner.sendTransaction({
      to: registry.address,
      value: ethers.utils.parseEther("1.0"),
    });

    const balanceBefore = await ethers.provider.getBalance(juror1.address);

    const tx = await registry.connect(owner).rewardJuror(juror1.address, rewardAmount);
    const receipt = await tx.wait();
    const gasUsed = receipt.gasUsed.mul(receipt.effectiveGasPrice);

    const balanceAfter = await ethers.provider.getBalance(juror1.address);
    expect(balanceAfter).to.be.above(balanceBefore);

    await expect(tx)
      .to.emit(registry, "JurorRewarded")
      .withArgs(juror1.address, rewardAmount);
  });

  it("should revert reward if not a juror", async () => {
    await expect(
      registry.connect(owner).rewardJuror(juror3.address, ethers.utils.parseEther("0.01"))
    ).to.be.revertedWith("Not a juror");
  });
});
