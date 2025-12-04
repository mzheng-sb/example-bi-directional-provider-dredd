const Product = require("./product");
const ProductRepository = require("./product.repository");

const repository = new ProductRepository();
const INVALID_ID_MESSAGE = "invalid product id: must be a valid integer";

exports.create = async (req, res) => {
    const data = req.body
    const id = parseInt(data.id, 10)
    if (isNaN(id)) {
        return res.status(400).send({message: INVALID_ID_MESSAGE})
    }
    const product = new Product(id, data.type, data.name, data.version, data.price)
    product ? res.send(product) : res.status(400).send({message: "invalid product"})
};
exports.getAll = async (req, res) => {
    res.send(await repository.fetchAll())
};
exports.getById = async (req, res) => {
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) {
        return res.status(400).send({message: INVALID_ID_MESSAGE})
    }
    const product = await repository.getById(id);
    product ? res.send(product) : res.status(404).send({message: "Product not found"})
};

exports.repository = repository;