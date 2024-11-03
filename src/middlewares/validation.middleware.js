function validateNFTInput(nftData) {
  if (!nftData.name) {
    return "Name is required";
  }

  if (!nftData.image && !nftData.imageUrl) {
    return "Image or imageUrl is required";
  }

  if (nftData.attributes && !Array.isArray(nftData.attributes)) {
    return "Attributes must be an array";
  }

  return null;
}

module.exports = { validateNFTInput };
