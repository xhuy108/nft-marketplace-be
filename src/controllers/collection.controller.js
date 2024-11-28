const collectionService = require("../services/collection.service");
const { validateCollection } = require("../validators/collection.validator");
const { AppError } = require("../middlewares/error.middleware");

exports.createCollection = async (req, res, next) => {
  try {
    const { error } = validateCollection(req.body);
    if (error) {
      throw new AppError(400, error.details[0].message);
    }

    const collection = await collectionService.createCollection(
      req.body,
      req.user.address
    );

    res.status(201).json({
      status: "success",
      data: collection,
    });
  } catch (error) {
    next(error);
  }
};

exports.getAllCollections = async (req, res, next) => {
  try {
    const collections = await collectionService.getAllCollections();

    res.status(200).json({
      status: "success",
      results: collections.length,
      data: collections,
    });
  } catch (error) {
    next(error);
  }
};
