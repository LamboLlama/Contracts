export class Whitelist {
    generateWhitelistSignature = async (whitelistSigner: any, user: any) => {
        const messageHash = ethers.utils.solidityKeccak256(["address"], [user.address]);
        const messageHashBinary = ethers.utils.arrayify(messageHash);
        return await whitelistSigner.signMessage(messageHashBinary);
    };
}
