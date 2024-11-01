const loginRouter = require("express").Router()
const User = require("../models/user")
const jwt = require("jsonwebtoken")
const bcrypt = require("bcrypt")

loginRouter.post("/", async (request, response) => {
    const { username, password } = request.body

    const user = await User.findOne({ username })
    console.log(user, password)
    const passwordCorrect = user === null
        ? false
        : await bcrypt.compare(password, user.passwordHash)

    if (!(user && passwordCorrect)) {
        return response.status(4001).json({
            error: "invalid username or password"
        })
    }

    const userForToken = {
        username: user.username,
        id: user._id
    }

    const token = jwt.sign(userForToken, process.env.SEKRET, { expiresIn: "1h" })
    response
        .status(200)
        .send({ token, username: user.username, name: user.name })
})

module.exports = loginRouter
