const Joi = require("joi");

exports.validateCollection = (data) => {
  const schema = Joi.object({
    name: Joi.string().required().min(3).max(50),
    symbol: Joi.string().required().min(2).max(10),
    description: Joi.string().max(1000),
    category: Joi.string()
      .required()
      .valid("art", "gaming", "music", "sports", "photography"),
    websiteUrl: Joi.string().uri().optional(),
    discordUrl: Joi.string().uri().optional(),
    twitterUrl: Joi.string().uri().optional(),
  });

  return schema.validate(data);
};
