const Product = require("./product");
const ProductRepository = require("./product.repository");

const repository = new ProductRepository();

exports.create = async (req, res) => {
    const data = req.body
    const product = new Product(data.id, data.type, data.name, data.version, data.price)
    product ? res.send(product) : res.status(400).send({message: "invalid product"})
};
exports.getAll = async (req, res) => {
    res.send(await repository.fetchAll())
};
exports.getById = async (req, res) => {
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) {
        return res.status(400).send({message: "Invalid product ID"});
    }
    const product = await repository.getById(id);
    product ? res.send(product) : res.status(404).send({message: "Product not found"})
};

exports.repository = repository;