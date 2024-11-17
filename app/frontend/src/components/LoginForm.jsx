import { useState } from "react"
import PropTypes from "prop-types"

const LoginForm = ({ login }) => {
    const [username, setUsername] = useState("")
    const [password, setPassword] = useState("")

    const handleLogin = (event) => {
        event.preventDefault()
        login({ username, password })
        setUsername("")
        setPassword("")
    }

    return (
        <form onSubmit={handleLogin}>
            <div>
                username: <input value={username} onChange={({ target }) => setUsername(target.value)} />
            </div>
            <div>
                password: <input value={password} onChange={({ target }) => setPassword(target.value)} />
            </div>
            <button type="submit">login</button>
        </form>
    )
}

LoginForm.propTypes = {
    login: PropTypes.func.isRequired
}

export default LoginForm
